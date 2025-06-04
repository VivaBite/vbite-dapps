// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/access/extensions/AccessControlEnumerable.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/utils/Pausable.sol";
import "@openzeppelin/utils/ReentrancyGuard.sol";
import "@openzeppelin/utils/cryptography/MerkleProof.sol";

/**
 * @title VBITE Airdrop Contract
 * @notice Daily round-based airdrop system using Merkle trees for gas optimization
 * @dev Each round starts at 00:00 UTC, users can claim from any round with valid proof
 * @dev Implements role-based access control for backend operations
 */
contract VBITEAirdrop is Ownable, Pausable, ReentrancyGuard, AccessControlEnumerable {
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

    uint256 public constant MAX_BATCH_SIZE = 50;
    uint256 public constant MAX_CLAIM_AMOUNT = 1_000_000 * 10**18;
    uint256 public constant MAX_ROUNDS_AHEAD = 365;

    uint256 public dailyClaimLimit = 10_000_000 * 10**18;
    mapping(uint256 => uint256) public dailyClaimed;

    uint256 public constant TIMELOCK_DELAY = 24 hours;
    mapping(bytes32 => uint256) public timelocks;

    // ==========================================
    // Access Control Roles
    // ==========================================
    
    /// @notice Role for backend services that can set Merkle roots
    bytes32 public constant BACKEND_ADMIN_ROLE = keccak256("BACKEND_ADMIN_ROLE");
    
    /// @notice Role for setting Merkle roots (can be granted to backend or automated systems)
    bytes32 public constant MERKLE_SETTER_ROLE = keccak256("MERKLE_SETTER_ROLE");
    
    /// @notice Role for emergency operations (pause, emergency withdraw)
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    
    /// @notice Role for updating operational parameters
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

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
    error AmountTooLarge(uint256 amount, uint256 maxAmount);
    error DailyClaimLimitExceeded(uint256 requested, uint256 available);
    error TooManyBatchOperations(uint256 length, uint256 maxLength);
    error IntegerOverflow();
    error DeploymentTimeTooFarInPast(uint256 deploymentTime, uint256 minimumTime);
    error CannotSetZeroMerkleRoot();
    error OperationNotProposed(bytes32 operation);
    error TimelockNotExpired(uint256 currentTime, uint256 requiredTime);
    error UnauthorizedRole(bytes32 role, address account);

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
    event LargeClaimAttempt(address indexed user, uint256 round, uint256 amount);
    event MerkleRootOverwritten(uint256 indexed round, bytes32 oldRoot, bytes32 newRoot);
    event EmergencyWithdraw(address indexed admin, uint256 amount, uint256 timestamp);
    event DailyClaimLimitUpdated(uint256 oldLimit, uint256 newLimit);
    event OperationProposed(bytes32 operation, uint256 executionTime);
    
    // Role management events
    event BackendAdminGranted(address indexed account, address indexed grantedBy);
    event BackendAdminRevoked(address indexed account, address indexed revokedBy);
    event MerkleSetterGranted(address indexed account, address indexed grantedBy);
    event MerkleSetterRevoked(address indexed account, address indexed revokedBy);
    event EmergencyRoleGranted(address indexed account, address indexed grantedBy);
    event OperatorRoleGranted(address indexed account, address indexed grantedBy);

    // ==========================================
    // Modifiers
    // ==========================================
    
    modifier onlyBackendAdmin() {
        if (!(hasRole(BACKEND_ADMIN_ROLE, msg.sender) || msg.sender == owner())) {
            revert UnauthorizedRole(BACKEND_ADMIN_ROLE, msg.sender);
        }
        _;
    }
    
    modifier onlyMerkleSetter() {
        if (!(hasRole(MERKLE_SETTER_ROLE, msg.sender) || msg.sender == owner())) {
            revert UnauthorizedRole(MERKLE_SETTER_ROLE, msg.sender);
        }
        _;
    }
    
    modifier onlyEmergencyRole() {
        if (!(hasRole(EMERGENCY_ROLE, msg.sender) || msg.sender == owner())) {
            revert UnauthorizedRole(EMERGENCY_ROLE, msg.sender);
        }
        _;
    }
    
    modifier onlyOperator() {
        if (!(hasRole(OPERATOR_ROLE, msg.sender) || msg.sender == owner())) {
            revert UnauthorizedRole(OPERATOR_ROLE, msg.sender);
        }
        _;
    }

    // ==========================================
    // Constructor
    // ==========================================

    /**
     * @notice Initialize airdrop contract with role-based access control
     * @param _vbiteToken Address of VBITE token contract
     * @param _ownerAddress Contract owner address
     * @param _deploymentTime Optional custom deployment time (use 0 for current time)
     */
    constructor(
        address _vbiteToken,
        address _ownerAddress,
        uint256 _deploymentTime
    ) Ownable(_ownerAddress) {
        if (_vbiteToken == address(0)) revert ZeroAddressProvided();
        if (_ownerAddress == address(0)) revert ZeroAddressProvided();
        
        vbiteToken = IERC20(_vbiteToken);
        
        if (_deploymentTime > 0) {
            if (_deploymentTime > block.timestamp) revert RoundInFuture(_deploymentTime, block.timestamp);
            if (_deploymentTime < block.timestamp - 7 days) {
                revert DeploymentTimeTooFarInPast(_deploymentTime, block.timestamp - 7 days);
            }
            deploymentTime = _deploymentTime;
        } else {
            deploymentTime = block.timestamp - (block.timestamp % ROUND_DURATION);
        }
        
        maxAllowedRound = getCurrentRound();
        
        // Setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, _ownerAddress);
        _grantRole(BACKEND_ADMIN_ROLE, _ownerAddress);
        _grantRole(MERKLE_SETTER_ROLE, _ownerAddress);
        _grantRole(EMERGENCY_ROLE, _ownerAddress);
        _grantRole(OPERATOR_ROLE, _ownerAddress);
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

    function hasUserClaimed(uint256 round, address user) external view returns (bool) {
        return hasClaimed[round][user];
    }

    function getRoundTimes(uint256 round) external view returns (uint256 startTime, uint256 endTime) {
        startTime = deploymentTime + (round * ROUND_DURATION);
        endTime = startTime + ROUND_DURATION - 1;
    }

    function isRoundClaimable(uint256 round) public view returns (bool) {
        return round <= maxAllowedRound && merkleRoots[round] != bytes32(0);
    }

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

    function getUserInfo(address user, uint256 round)
        external 
        view 
        returns (
            bool userHasClaimed,
            bool hasRoot, 
            bool canClaim,
            bool roundExists
        ) 
    {
        userHasClaimed = hasClaimed[round][user];
        hasRoot = merkleRoots[round] != bytes32(0);
        roundExists = round <= maxAllowedRound;
        canClaim = roundExists && hasRoot && !userHasClaimed;
    }

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
            uint256 targetRound = rounds[i];
            claimedStatus[i] = hasClaimed[targetRound][user];
            hasRoots[i] = merkleRoots[targetRound] != bytes32(0);
            canClaims[i] = targetRound <= maxAllowedRound && hasRoots[i] && !claimedStatus[i];
        }
    }

    // ==========================================
    // User Functions
    // ==========================================

    function claim(
        uint256 round,
        uint256 amount,
        bytes32[] calldata proof
    ) external whenNotPaused nonReentrant {
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
        if (amount > 100_000 * 10**18) {
            emit LargeClaimAttempt(msg.sender, round, amount);
        }
    }

    function batchClaim(
        uint256[] calldata rounds,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) external whenNotPaused nonReentrant {
        uint256 length = rounds.length;
        if (length != amounts.length || length != proofs.length) {
            revert ArrayLengthMismatch();
        }
        
        if (length > MAX_BATCH_SIZE) revert TooManyBatchOperations(length, MAX_BATCH_SIZE);
        
        uint256 totalAmount = 0;
        
        uint256 currentDay = block.timestamp / 1 days;
        uint256 dailyAvailable = dailyClaimLimit - dailyClaimed[currentDay];

        // Verify all claims first
        for (uint256 i = 0; i < length; i++) {
            uint256 targetRound = rounds[i];
            uint256 claimAmount = amounts[i];
            
            if (claimAmount == 0) revert ZeroAmountProvided();
            if (targetRound > maxAllowedRound) revert RoundNotExists(targetRound, maxAllowedRound);
            if (hasClaimed[targetRound][msg.sender]) revert AlreadyClaimedInRound(targetRound, msg.sender);
            if (merkleRoots[targetRound] == bytes32(0)) revert MerkleRootNotSet(targetRound);

            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, claimAmount));
            if (!MerkleProof.verify(proofs[i], merkleRoots[targetRound], leaf)) {
                revert InvalidMerkleProof();
            }

            uint256 newTotal = totalAmount + claimAmount;
            if (newTotal < totalAmount) revert IntegerOverflow();
            totalAmount = newTotal;
        }

        if (totalAmount > dailyAvailable) {
            revert DailyClaimLimitExceeded(totalAmount, dailyAvailable);
        }

        // Check contract has enough tokens
        uint256 contractBalance = vbiteToken.balanceOf(address(this));
        if (contractBalance < totalAmount) {
            revert InsufficientContractBalance(totalAmount, contractBalance);
        }

        // Execute all claims
        for (uint256 i = 0; i < length; i++) {
            uint256 targetRound = rounds[i];
            uint256 claimAmount = amounts[i];

            hasClaimed[targetRound][msg.sender] = true;
            totalClaimedPerRound[targetRound] += claimAmount;
            totalClaimedByUser[msg.sender] += claimAmount;
            totalClaimed += claimAmount;

            emit TokensClaimed(msg.sender, targetRound, claimAmount, totalClaimedByUser[msg.sender]);
        }

        dailyClaimed[currentDay] += totalAmount;

        // Single token transfer
        vbiteToken.safeTransfer(msg.sender, totalAmount);
    }

    // ==========================================
    // Role Management Functions (Owner Only)
    // ==========================================

    function grantBackendAdmin(address account) external onlyOwner {
        if (account == address(0)) revert ZeroAddressProvided();
        _grantRole(BACKEND_ADMIN_ROLE, account);
        emit BackendAdminGranted(account, msg.sender);
    }

    function revokeBackendAdmin(address account) external onlyOwner {
        _revokeRole(BACKEND_ADMIN_ROLE, account);
        emit BackendAdminRevoked(account, msg.sender);
    }

    function grantMerkleSetter(address account) external onlyOwner {
        if (account == address(0)) revert ZeroAddressProvided();
        _grantRole(MERKLE_SETTER_ROLE, account);
        emit MerkleSetterGranted(account, msg.sender);
    }

    function revokeMerkleSetter(address account) external onlyOwner {
        _revokeRole(MERKLE_SETTER_ROLE, account);
        emit MerkleSetterRevoked(account, msg.sender);
    }

    function grantEmergencyRole(address account) external onlyOwner {
        if (account == address(0)) revert ZeroAddressProvided();
        _grantRole(EMERGENCY_ROLE, account);
        emit EmergencyRoleGranted(account, msg.sender);
    }

    function grantOperatorRole(address account) external onlyOwner {
        if (account == address(0)) revert ZeroAddressProvided();
        _grantRole(OPERATOR_ROLE, account);
        emit OperatorRoleGranted(account, msg.sender);
    }

    // ==========================================
    // Backend Admin Functions
    // ==========================================

    function setMerkleRootByBackend(uint256 round, bytes32 merkleRoot) external onlyMerkleSetter {
        if (round > getCurrentRound()) revert RoundInFuture(round, getCurrentRound());
        if (merkleRoot == bytes32(0)) revert CannotSetZeroMerkleRoot();
        
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
     * @notice Set Merkle roots for multiple rounds (Backend Admin)
     */
    function setMerkleRootsBatchByBackend(
        uint256[] calldata rounds,
        bytes32[] calldata merkleRootArray
    ) external onlyMerkleSetter {
        if (rounds.length != merkleRootArray.length) {
            revert ArrayLengthMismatch();
        }

        uint256 currentRoundNum = getCurrentRound();
        uint256 maxRound = lastRoundWithRoot;
        uint256 newMaxAllowed = maxAllowedRound;

        for (uint256 i = 0; i < rounds.length; i++) {
            uint256 targetRound = rounds[i];
            if (targetRound > currentRoundNum) revert RoundInFuture(targetRound, currentRoundNum);
            if (merkleRootArray[i] == bytes32(0)) revert CannotSetZeroMerkleRoot();
            
            merkleRoots[targetRound] = merkleRootArray[i];
            
            if (targetRound > maxRound) {
                maxRound = targetRound;
            }
            if (targetRound > newMaxAllowed) {
                newMaxAllowed = targetRound;
            }

            emit MerkleRootSet(targetRound, merkleRootArray[i], msg.sender);
        }

        lastRoundWithRoot = maxRound;
        if (newMaxAllowed > maxAllowedRound) {
            emit MaxAllowedRoundUpdated(maxAllowedRound, newMaxAllowed, msg.sender);
            maxAllowedRound = newMaxAllowed;
        }
    }

    /**
     * @notice Update daily claim limit (Operator)
     */
    function updateDailyClaimLimitByOperator(uint256 newLimit) external onlyOperator {
        emit DailyClaimLimitUpdated(dailyClaimLimit, newLimit);
        dailyClaimLimit = newLimit;
    }

    /**
     * @notice Emergency pause by authorized role
     */
    function emergencyPause() external onlyEmergencyRole {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Emergency unpause by authorized role
     */
    function emergencyUnpause() external onlyEmergencyRole {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    // ==========================================
    // Owner Admin Functions
    // ==========================================

    /**
     * @notice Set Merkle root for specific round (Owner)
     */
    function setMerkleRoot(uint256 round, bytes32 merkleRoot) external onlyMerkleSetter {
        if (merkleRoot == bytes32(0)) revert CannotSetZeroMerkleRoot();
        if (round > getCurrentRound() + MAX_ROUNDS_AHEAD) {
            revert RoundInFuture(round, getCurrentRound());
        }

        if (merkleRoots[round] != bytes32(0)) {
            emit MerkleRootOverwritten(round, merkleRoots[round], merkleRoot);
        }

        merkleRoots[round] = merkleRoot;
        
        lastRoundWithRoot = round;

        if (round > maxAllowedRound) {
            maxAllowedRound = round;
            emit MaxAllowedRoundUpdated(maxAllowedRound, round, msg.sender);
        }

        emit MerkleRootSet(round, merkleRoot, msg.sender);
    }

    /**
     * @notice Set Merkle roots for multiple rounds (Owner)
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
            uint256 targetRound = rounds[i];
            if (targetRound > currentRoundNum) revert RoundInFuture(targetRound, currentRoundNum);
            
            merkleRoots[targetRound] = merkleRootArray[i];
            
            if (targetRound > maxRound) {
                maxRound = targetRound;
            }
            if (targetRound > newMaxAllowed) {
                newMaxAllowed = targetRound;
            }

            emit MerkleRootSet(targetRound, merkleRootArray[i], msg.sender);
        }

        lastRoundWithRoot = maxRound;
        if (newMaxAllowed > maxAllowedRound) {
            emit MaxAllowedRoundUpdated(maxAllowedRound, newMaxAllowed, msg.sender);
            maxAllowedRound = newMaxAllowed;
        }
    }

    /**
     * @notice Update max allowed round (Owner)
     */
    function updateMaxAllowedRound(uint256 newMaxRound) external onlyOwner {
        if (newMaxRound > getCurrentRound()) revert RoundInFuture(newMaxRound, getCurrentRound());
        
        uint256 oldMaxRound = maxAllowedRound;
        maxAllowedRound = newMaxRound;
        
        emit MaxAllowedRoundUpdated(oldMaxRound, newMaxRound, msg.sender);
    }

    /**
     * @notice Deposit VBITE tokens to contract (Owner)
     */
    function depositTokens(uint256 amount) external onlyOwner {
        if (amount == 0) revert ZeroAmountProvided();
        
        vbiteToken.safeTransferFrom(msg.sender, address(this), amount);
        
        emit TokensDeposited(msg.sender, amount, vbiteToken.balanceOf(address(this)));
    }

    /**
     * @notice Withdraw VBITE tokens from contract (Owner)
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
     * @notice Update daily claim limit (Owner)
     * @param newLimit New daily claim limit
     */
    function updateDailyClaimLimit(uint256 newLimit) external onlyOwner {
        emit DailyClaimLimitUpdated(dailyClaimLimit, newLimit);
        dailyClaimLimit = newLimit;
    }

    /**
     * @notice Propose emergency withdraw operation (Owner)
     */
    function proposeEmergencyWithdraw() external onlyOwner {
        bytes32 operation = keccak256("EMERGENCY_WITHDRAW");
        timelocks[operation] = block.timestamp + TIMELOCK_DELAY;
        emit OperationProposed(operation, block.timestamp + TIMELOCK_DELAY);
    }

    /**
     * @notice Execute emergency withdraw after timelock (Owner)
     */
    function executeEmergencyWithdraw() external onlyOwner {
        bytes32 operation = keccak256("EMERGENCY_WITHDRAW");
        
        if (timelocks[operation] == 0) revert OperationNotProposed(operation);
        if (block.timestamp < timelocks[operation]) {
            revert TimelockNotExpired(block.timestamp, timelocks[operation]);
        }
        
        delete timelocks[operation];
        
        uint256 balance = vbiteToken.balanceOf(address(this));
        if (balance > 0) {
            vbiteToken.safeTransfer(msg.sender, balance);
            emit EmergencyWithdraw(msg.sender, balance, block.timestamp);
        }
    }

    /**
     * @notice Emergency withdraw all tokens (Owner)
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = vbiteToken.balanceOf(address(this));
        if (balance > 0) {
            vbiteToken.safeTransfer(msg.sender, balance);
            emit TokensWithdrawn(msg.sender, balance, 0);
        }
    }

    /**
     * @notice Pause contract operations (Owner)
     */
    function pause() external onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpause contract operations (Owner)
     */
    function unpause() external onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    // ==========================================
    // View Functions for Role Management
    // ==========================================

    /**
     * @notice Check if address has backend admin role
     */
    function isBackendAdmin(address account) external view returns (bool) {
        return hasRole(BACKEND_ADMIN_ROLE, account);
    }

    function isMerkleSetter(address account) external view returns (bool) {
        return hasRole(MERKLE_SETTER_ROLE, account);
    }

    function hasEmergencyRole(address account) external view returns (bool) {
        return hasRole(EMERGENCY_ROLE, account);
    }

    function isOperator(address account) external view returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }

    /**
     * @notice Support interface detection
     * @param interfaceId Interface identifier to check
     * @return True if interface is supported
     */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(AccessControlEnumerable) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}