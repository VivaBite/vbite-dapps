// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/utils/Pausable.sol";
import "@openzeppelin/utils/ReentrancyGuard.sol";
import "@openzeppelin/utils/cryptography/MerkleProof.sol";

/**
 * @title VBITE Airdrop Contract
 * @notice Daily round-based airdrop system using Merkle trees for gas optimization
 * @dev Each round starts at 00:00 UTC, users can claim from any round with valid proof
 */
contract VBITEAirdrop is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ==========================================
    // Constants & State Variables
    // ==========================================

    /// @notice VBITE token contract
    IERC20 public immutable vbiteToken;
    
    /// @notice Duration of each round in seconds (1 day)
    uint256 public constant ROUND_DURATION = 1 days;
    
    /// @notice Contract deployment timestamp (round 0 start at 00:00 UTC)
    uint256 public immutable deploymentTime;
    
    /// @notice Last round for which Merkle root was set
    uint256 public lastRoundWithRoot;
    
    /// @notice Maximum allowed round number (prevents claiming from future rounds)
    uint256 public maxAllowedRound;
    
    /// @notice Merkle root for each round
    mapping(uint256 => bytes32) public merkleRoots;
    
    /// @notice Track if user has claimed in specific round: round => user => claimed
    mapping(uint256 => mapping(address => bool)) public hasClaimed;
    
    /// @notice Total tokens claimed per round
    mapping(uint256 => uint256) public totalClaimedPerRound;
    
    /// @notice Total tokens claimed by each user across all rounds
    mapping(address => uint256) public totalClaimedByUser;
    
    /// @notice Total tokens claimed across all rounds
    uint256 public totalClaimed;

    // Добавить константы для защиты
    uint256 public constant MAX_BATCH_SIZE = 50;
    uint256 public constant MAX_CLAIM_AMOUNT = 1_000_000 * 10**18; // 1M токенов
    uint256 public constant MAX_ROUNDS_AHEAD = 365; // Максимум на год вперед

    // Добавить переменные состояния
    uint256 public dailyClaimLimit = 10_000_000 * 10**18; // 10M токенов в день
    mapping(uint256 => uint256) public dailyClaimed; // день => количество

    // Для повышения доверия пользователей
    uint256 public constant TIMELOCK_DELAY = 24 hours;
    mapping(bytes32 => uint256) public timelocks;

    // ==========================================
    // Custom Errors
    // ==========================================

    error ZeroAddressProvided();
    error ZeroAmountProvided();
    error RoundNotExists(uint256 round, uint256 maxRound);
    error InvalidMerkleProof();
    error AlreadyClaimedInRound(uint256 round, address user);
    error MerkleRootNotSet(uint256 round);
    error InsufficientContractBalance(uint256 required, uint256 available);
    error RoundInFuture(uint256 round, uint256 currentRound);
    error ArrayLengthMismatch();
    
    // 🔥 НОВЫЕ кастомные ошибки взамен require и строк
    error AmountTooLarge(uint256 amount, uint256 maxAmount);
    error DailyClaimLimitExceeded(uint256 requested, uint256 available);
    error TooManyBatchOperations(uint256 length, uint256 maxLength);
    error IntegerOverflow();
    error DeploymentTimeTooFarInPast(uint256 deploymentTime, uint256 minimumTime);
    error CannotSetZeroMerkleRoot();
    error OperationNotProposed(bytes32 operation);
    error TimelockNotExpired(uint256 currentTime, uint256 requiredTime);

    // ==========================================
    // Events
    // ==========================================

    event TokensClaimed(
        address indexed user,
        uint256 indexed round,
        uint256 amount,
        uint256 totalUserClaimed
    );
    
    event MerkleRootSet(
        uint256 indexed round,
        bytes32 merkleRoot,
        address indexed admin
    );
    
    event MaxAllowedRoundUpdated(
        uint256 oldMaxRound,
        uint256 newMaxRound,
        address indexed admin
    );
    
    event TokensDeposited(
        address indexed admin,
        uint256 amount,
        uint256 newBalance
    );
    
    event TokensWithdrawn(
        address indexed admin,
        uint256 amount,
        uint256 remainingBalance
    );
    
    event ContractPaused(address indexed admin);
    event ContractUnpaused(address indexed admin);

    // Дополнительные события для мониторинга
    event LargeClaimAttempt(address indexed user, uint256 round, uint256 amount);
    event MerkleRootOverwritten(uint256 indexed round, bytes32 oldRoot, bytes32 newRoot);
    event EmergencyWithdraw(address indexed admin, uint256 amount, uint256 timestamp);
    event DailyClaimLimitUpdated(uint256 oldLimit, uint256 newLimit);
    event OperationProposed(bytes32 operation, uint256 executionTime);

    // ==========================================
    // Constructor
    // ==========================================

    /**
     * @notice Initialize airdrop contract
     * @param _vbiteToken Address of VBITE token contract
     * @param _owner Contract owner address
     * @param _deploymentTime Optional custom deployment time (use 0 for current time)
     */
    constructor(
        address _vbiteToken,
        address _owner,
        uint256 _deploymentTime
    ) Ownable(_owner) {
        if (_vbiteToken == address(0)) revert ZeroAddressProvided();
        if (_owner == address(0)) revert ZeroAddressProvided();
        
        vbiteToken = IERC20(_vbiteToken);
        
        if (_deploymentTime > 0) {
            // ✅ ЗАМЕНЕНО: Добавляем проверку на разумное время
            if (_deploymentTime > block.timestamp) revert RoundInFuture(_deploymentTime, block.timestamp);
            if (_deploymentTime < block.timestamp - 7 days) {
                revert DeploymentTimeTooFarInPast(_deploymentTime, block.timestamp - 7 days);
            }
            deploymentTime = _deploymentTime;
        } else {
            // Align to midnight UTC с дополнительной проверкой
            uint256 alignedTime = (block.timestamp / ROUND_DURATION) * ROUND_DURATION;
            deploymentTime = alignedTime;
        }
        
        maxAllowedRound = getCurrentRound();
    }

    // ==========================================
    // View Functions
    // ==========================================

    /**
     * @notice Get current round number based on time (00:00 UTC boundaries)
     * @return Current round number
     */
    function getCurrentRound() public view returns (uint256) {
        return (block.timestamp - deploymentTime) / ROUND_DURATION;
    }

    /**
     * @notice Check if user has claimed tokens in specific round
     * @param round Round number to check
     * @param user User address
     * @return True if user has claimed in this round
     */
    function hasUserClaimed(uint256 round, address user) external view returns (bool) {
        return hasClaimed[round][user];
    }

    /**
     * @notice Get contract's VBITE token balance
     * @return Available token balance
     */
    function getContractBalance() external view returns (uint256) {
        return vbiteToken.balanceOf(address(this));
    }

    /**
     * @notice Get round start and end timestamps (aligned to 00:00 UTC)
     * @param round Round number
     * @return startTime Round start timestamp (00:00 UTC)
     * @return endTime Round end timestamp (23:59:59 UTC)
     */
    function getRoundTimes(uint256 round) external view returns (uint256 startTime, uint256 endTime) {
        startTime = deploymentTime + (round * ROUND_DURATION);
        endTime = startTime + ROUND_DURATION - 1; // 23:59:59 of the same day
    }

    /**
     * @notice Check if round exists and can be claimed from
     * @param round Round number to check
     * @return True if round exists and is claimable
     */
    function isRoundClaimable(uint256 round) public view returns (bool) {
        return round <= maxAllowedRound && merkleRoots[round] != bytes32(0);
    }

    /**
     * @notice Verify Merkle proof without claiming
     * @param round Round number
     * @param amount Token amount to claim
     * @param proof Merkle proof array
     * @param user User address (can be different from msg.sender for verification)
     * @return True if proof is valid
     */
    function verifyProof(
        uint256 round,
        uint256 amount,
        bytes32[] calldata proof,
        address user
    ) external view returns (bool) {
        if (merkleRoots[round] == bytes32(0)) return false;
        
        bytes32 leaf = keccak256(abi.encodePacked(user, amount));
        return MerkleProof.verify(proof, merkleRoots[round], leaf);
    }

    /**
     * @notice Get user information for a specific round
     * @param user User address
     * @param round Round number
     * @return hasClaimed_ Whether user has claimed in this round
     * @return hasRoot Whether Merkle root is set for this round
     * @return canClaim Whether user can claim from this round
     * @return roundExists Whether round exists (not in future)
     */
    function getUserInfo(address user, uint256 round) 
        external 
        view 
        returns (
            bool hasClaimed_, 
            bool hasRoot, 
            bool canClaim,
            bool roundExists
        ) 
    {
        hasClaimed_ = hasClaimed[round][user];
        hasRoot = merkleRoots[round] != bytes32(0);
        roundExists = round <= maxAllowedRound;
        canClaim = roundExists && hasRoot && !hasClaimed_;
    }

    /**
     * @notice Get multiple rounds information for a user
     * @param user User address
     * @param rounds Array of round numbers to check
     * @return claimedStatus Array of claim statuses
     * @return hasRoots Array of root existence statuses
     * @return canClaims Array of claimability statuses
     */
    function getUserInfoBatch(address user, uint256[] calldata rounds)
        external
        view
        returns (
            bool[] memory claimedStatus,
            bool[] memory hasRoots,
            bool[] memory canClaims
        )
    {
        uint256 length = rounds.length;
        claimedStatus = new bool[](length);
        hasRoots = new bool[](length);
        canClaims = new bool[](length);
        
        for (uint256 i = 0; i < length; i++) {
            uint256 round = rounds[i];
            claimedStatus[i] = hasClaimed[round][user];
            hasRoots[i] = merkleRoots[round] != bytes32(0);
            canClaims[i] = round <= maxAllowedRound && hasRoots[i] && !claimedStatus[i];
        }
    }

    // ==========================================
    // User Functions
    // ==========================================

    /**
     * @notice Claim tokens for specific round
     * @param round Round number to claim for
     * @param amount Amount of tokens to claim
     * @param proof Merkle proof for the claim
     */
    function claim(
        uint256 round,
        uint256 amount,
        bytes32[] calldata proof
    ) external whenNotPaused nonReentrant {
        // ✅ ЗАМЕНЕНО: Проверка максимальной суммы
        if (amount > MAX_CLAIM_AMOUNT) revert AmountTooLarge(amount, MAX_CLAIM_AMOUNT);
        if (amount == 0) revert ZeroAmountProvided();
        if (round > maxAllowedRound) revert RoundNotExists(round, maxAllowedRound);
        if (hasClaimed[round][msg.sender]) revert AlreadyClaimedInRound(round, msg.sender);
        if (merkleRoots[round] == bytes32(0)) revert MerkleRootNotSet(round);

        // Verify Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        if (!MerkleProof.verify(proof, merkleRoots[round], leaf)) {
            revert InvalidMerkleProof();
        }

        // ✅ ЗАМЕНЕНО: Проверка дневного лимита
        uint256 currentDay = block.timestamp / 1 days;
        uint256 dailyAvailable = dailyClaimLimit - dailyClaimed[currentDay];
        if (amount > dailyAvailable) {
            revert DailyClaimLimitExceeded(amount, dailyAvailable);
        }

        // Check contract has enough tokens
        uint256 contractBalance = vbiteToken.balanceOf(address(this));
        if (contractBalance < amount) {
            revert InsufficientContractBalance(amount, contractBalance);
        }

        // Mark as claimed and update statistics
        hasClaimed[round][msg.sender] = true;
        totalClaimedPerRound[round] += amount;
        totalClaimedByUser[msg.sender] += amount;
        totalClaimed += amount;

        // Update daily claimed amount
        dailyClaimed[currentDay] += amount;

        // Transfer tokens
        vbiteToken.safeTransfer(msg.sender, amount);

        emit TokensClaimed(msg.sender, round, amount, totalClaimedByUser[msg.sender]);

        // Large claim monitoring
        if (amount > 100_000 * 10**18) { // Больше 100K токенов
            emit LargeClaimAttempt(msg.sender, round, amount);
        }
    }

    /**
     * @notice Batch claim tokens for multiple rounds
     * @param rounds Array of round numbers
     * @param amounts Array of token amounts
     * @param proofs Array of Merkle proofs
     */
    function batchClaim(
        uint256[] calldata rounds,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) external whenNotPaused nonReentrant {
        uint256 length = rounds.length;
        if (length != amounts.length || length != proofs.length) {
            revert ArrayLengthMismatch();
        }
        
        // ✅ ЗАМЕНЕНО: Ограничение на количество batch операций
        if (length > MAX_BATCH_SIZE) revert TooManyBatchOperations(length, MAX_BATCH_SIZE);
        
        uint256 totalAmount = 0;

        // Verify all claims first
        for (uint256 i = 0; i < length; i++) {
            uint256 round = rounds[i];
            uint256 amount = amounts[i];
            
            if (amount == 0) revert ZeroAmountProvided();
            if (round > maxAllowedRound) revert RoundNotExists(round, maxAllowedRound);
            if (hasClaimed[round][msg.sender]) revert AlreadyClaimedInRound(round, msg.sender);
            if (merkleRoots[round] == bytes32(0)) revert MerkleRootNotSet(round);

            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
            if (!MerkleProof.verify(proofs[i], merkleRoots[round], leaf)) {
                revert InvalidMerkleProof();
            }

            // ✅ ЗАМЕНЕНО: Защита от overflow
            uint256 newTotal = totalAmount + amount;
            if (newTotal < totalAmount) revert IntegerOverflow();
            totalAmount = newTotal;
        }

        // Check contract has enough tokens
        uint256 contractBalance = vbiteToken.balanceOf(address(this));
        if (contractBalance < totalAmount) {
            revert InsufficientContractBalance(totalAmount, contractBalance);
        }

        // Execute all claims
        for (uint256 i = 0; i < length; i++) {
            uint256 round = rounds[i];
            uint256 amount = amounts[i];

            hasClaimed[round][msg.sender] = true;
            totalClaimedPerRound[round] += amount;
            totalClaimedByUser[msg.sender] += amount;
            totalClaimed += amount;

            emit TokensClaimed(msg.sender, round, amount, totalClaimedByUser[msg.sender]);
        }

        // Single token transfer
        vbiteToken.safeTransfer(msg.sender, totalAmount);
    }

    // ==========================================
    // Admin Functions
    // ==========================================

    /**
     * @notice Set Merkle root for specific round
     * @param round Round number
     * @param merkleRoot Merkle tree root hash
     */
    function setMerkleRoot(uint256 round, bytes32 merkleRoot) external onlyOwner {
        if (round > getCurrentRound()) revert RoundInFuture(round, getCurrentRound());
        
        // ✅ ЗАМЕНЕНО: Запрет на установку нулевого root
        if (merkleRoot == bytes32(0)) revert CannotSetZeroMerkleRoot();
        
        // Проверка на перезапись существующего root
        if (merkleRoots[round] != bytes32(0)) {
            emit MerkleRootOverwritten(round, merkleRoots[round], merkleRoot);
        }
        
        merkleRoots[round] = merkleRoot;
        
        if (round > lastRoundWithRoot) {
            lastRoundWithRoot = round;
        }
        if (round > maxAllowedRound) {
            maxAllowedRound = round;
        }

        emit MerkleRootSet(round, merkleRoot, msg.sender);
    }

    /**
     * @notice Set Merkle roots for multiple rounds
     * @param rounds Array of round numbers
     * @param merkleRootArray Array of Merkle roots
     */
    function setMerkleRoots(
        uint256[] calldata rounds,
        bytes32[] calldata merkleRootArray
    ) external onlyOwner {
        if (rounds.length != merkleRootArray.length) {
            revert ArrayLengthMismatch();
        }

        uint256 currentRoundNum = getCurrentRound();
        uint256 maxRound = lastRoundWithRoot;
        uint256 newMaxAllowed = maxAllowedRound;

        for (uint256 i = 0; i < rounds.length; i++) {
            uint256 round = rounds[i];
            if (round > currentRoundNum) revert RoundInFuture(round, currentRoundNum);
            
            merkleRoots[round] = merkleRootArray[i];
            
            if (round > maxRound) {
                maxRound = round;
            }
            if (round > newMaxAllowed) {
                newMaxAllowed = round;
            }

            emit MerkleRootSet(round, merkleRootArray[i], msg.sender);
        }

        lastRoundWithRoot = maxRound;
        if (newMaxAllowed > maxAllowedRound) {
            emit MaxAllowedRoundUpdated(maxAllowedRound, newMaxAllowed, msg.sender);
            maxAllowedRound = newMaxAllowed;
        }
    }

    /**
     * @notice Update max allowed round (in case need to extend claimable rounds)
     * @param newMaxRound New maximum round number
     */
    function updateMaxAllowedRound(uint256 newMaxRound) external onlyOwner {
        if (newMaxRound > getCurrentRound()) revert RoundInFuture(newMaxRound, getCurrentRound());
        
        uint256 oldMaxRound = maxAllowedRound;
        maxAllowedRound = newMaxRound;
        
        emit MaxAllowedRoundUpdated(oldMaxRound, newMaxRound, msg.sender);
    }

    /**
     * @notice Deposit VBITE tokens to contract
     * @param amount Amount of tokens to deposit
     */
    function depositTokens(uint256 amount) external onlyOwner {
        if (amount == 0) revert ZeroAmountProvided();
        
        vbiteToken.safeTransferFrom(msg.sender, address(this), amount);
        
        emit TokensDeposited(msg.sender, amount, vbiteToken.balanceOf(address(this)));
    }

    /**
     * @notice Withdraw VBITE tokens from contract
     * @param amount Amount of tokens to withdraw
     */
    function withdrawTokens(uint256 amount) external onlyOwner {
        if (amount == 0) revert ZeroAmountProvided();
        
        uint256 contractBalance = vbiteToken.balanceOf(address(this));
        if (contractBalance < amount) {
            revert InsufficientContractBalance(amount, contractBalance);
        }
        
        vbiteToken.safeTransfer(msg.sender, amount);
        
        emit TokensWithdrawn(msg.sender, amount, vbiteToken.balanceOf(address(this)));
    }

    /**
     * @notice Emergency withdraw all tokens
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = vbiteToken.balanceOf(address(this));
        if (balance > 0) {
            vbiteToken.safeTransfer(msg.sender, balance);
            emit TokensWithdrawn(msg.sender, balance, 0);
        }
    }

    /**
     * @notice Update daily claim limit
     * @param newLimit New daily claim limit
     */
    function updateDailyClaimLimit(uint256 newLimit) external onlyOwner {
        emit DailyClaimLimitUpdated(dailyClaimLimit, newLimit);
        dailyClaimLimit = newLimit;
    }

    /**
     * @notice Propose emergency withdraw operation
     */
    function proposeEmergencyWithdraw() external onlyOwner {
        bytes32 operation = keccak256("EMERGENCY_WITHDRAW");
        timelocks[operation] = block.timestamp + TIMELOCK_DELAY;
        emit OperationProposed(operation, block.timestamp + TIMELOCK_DELAY);
    }

    /**
     * @notice Execute emergency withdraw after timelock
     */
    function executeEmergencyWithdraw() external onlyOwner {
        bytes32 operation = keccak256("EMERGENCY_WITHDRAW");
        
        // ✅ ЗАМЕНЕНО: Проверки timelock
        if (timelocks[operation] == 0) revert OperationNotProposed(operation);
        if (block.timestamp < timelocks[operation]) {
            revert TimelockNotExpired(block.timestamp, timelocks[operation]);
        }
        
        delete timelocks[operation];
        
        // Выполнить emergency withdraw
        uint256 balance = vbiteToken.balanceOf(address(this));
        if (balance > 0) {
            vbiteToken.safeTransfer(msg.sender, balance);
            emit EmergencyWithdraw(msg.sender, balance, block.timestamp);
        }
    }

    /**
     * @notice Pause contract operations
     */
    function pause() external onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpause contract operations
     */
    function unpause() external onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }
}