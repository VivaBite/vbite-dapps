// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/access/AccessControl.sol";
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
contract VBITEAirdrop is Ownable, Pausable, ReentrancyGuard, AccessControl {
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
    uint256 public constant MAX_CLAIM_AMOUNT = 1_000_000 * 10**18; // 1M токенов
    uint256 public constant MAX_ROUNDS_AHEAD = 365; // Максимум на год вперед

    uint256 public dailyClaimLimit = 10_000_000 * 10**18; // 10M токенов в день
    mapping(uint256 => uint256) public dailyClaimed; // день => количество

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
        if (!hasRole(BACKEND_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedRole(BACKEND_ADMIN_ROLE, msg.sender);
        }
        _;
    }
    
    modifier onlyMerkleSetter() {
        if (!hasRole(MERKLE_SETTER_ROLE, msg.sender)) {
            revert UnauthorizedRole(MERKLE_SETTER_ROLE, msg.sender);
        }
        _;
    }
    
    modifier onlyEmergencyRole() {
        if (!hasRole(EMERGENCY_ROLE, msg.sender)) {
            revert UnauthorizedRole(EMERGENCY_ROLE, msg.sender);
        }
        _;
    }
    
    modifier onlyOperator() {
        if (!hasRole(OPERATOR_ROLE, msg.sender)) {
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
            uint256 alignedTime = (block.timestamp / ROUND_DURATION) * ROUND_DURATION;
            deploymentTime = alignedTime;
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

    /**
     * @notice Check if user has claimed tokens in specific round
     * @param _round Round number to check
     * @param _user User address
     * @return True if user has claimed in this round
     */
    function hasUserClaimed(uint256 _round, address _user) external view returns (bool) {
        return hasClaimed[_round][_user];
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
     * @param _round Round number
     * @return startTime Round start timestamp (00:00 UTC)
     * @return endTime Round end timestamp (23:59:59 UTC)
     */
    function getRoundTimes(uint256 _round) external view returns (uint256 startTime, uint256 endTime) {
        startTime = deploymentTime + (_round * ROUND_DURATION);
        endTime = startTime + ROUND_DURATION - 1;
    }

    /**
     * @notice Check if round exists and can be claimed from
     * @param _round Round number to check
     * @return True if round exists and is claimable
     */
    function isRoundClaimable(uint256 _round) public view returns (bool) {
        return _round <= maxAllowedRound && merkleRoots[_round] != bytes32(0);
    }

    /**
     * @notice Verify Merkle proof without claiming
     * @param _round Round number
     * @param _amount Token amount to claim
     * @param _proof Merkle proof array
     * @param _user User address (can be different from msg.sender for verification)
     * @return True if proof is valid
     */
    function verifyProof(
        uint256 _round,
        uint256 _amount,
        bytes32[] calldata _proof,
        address _user
    ) external view returns (bool) {
        if (merkleRoots[_round] == bytes32(0)) return false;
        
        bytes32 leaf = keccak256(abi.encodePacked(_user, _amount));
        return MerkleProof.verify(_proof, merkleRoots[_round], leaf);
    }

    /**
     * @notice Get user information for a specific round
     * @param _user User address
     * @param _round Round number
     * @return hasClaimed_ Whether user has claimed in this round
     * @return hasRoot Whether Merkle root is set for this round
     * @return canClaim Whether user can claim from this round
     * @return roundExists Whether round exists (not in future)
     */
    function getUserInfo(address _user, uint256 _round) 
        external 
        view 
        returns (
            bool hasClaimed_, 
            bool hasRoot, 
            bool canClaim,
            bool roundExists
        ) 
    {
        hasClaimed_ = hasClaimed[_round][_user];
        hasRoot = merkleRoots[_round] != bytes32(0);
        roundExists = _round <= maxAllowedRound;
        canClaim = roundExists && hasRoot && !hasClaimed_;
    }

    /**
     * @notice Get multiple rounds information for a user
     * @param _user User address
     * @param _rounds Array of round numbers to check
     * @return claimedStatus Array of claim statuses
     * @return hasRoots Array of root existence statuses
     * @return canClaims Array of claimability statuses
     */
    function getUserInfoBatch(address _user, uint256[] calldata _rounds)
        external
        view
        returns (
            bool[] memory claimedStatus,
            bool[] memory hasRoots,
            bool[] memory canClaims
        )
    {
        uint256 length = _rounds.length;
        claimedStatus = new bool[](length);
        hasRoots = new bool[](length);
        canClaims = new bool[](length);
        
        for (uint256 i = 0; i < length; i++) {
            uint256 targetRound = _rounds[i];
            claimedStatus[i] = hasClaimed[targetRound][_user];
            hasRoots[i] = merkleRoots[targetRound] != bytes32(0);
            canClaims[i] = targetRound <= maxAllowedRound && hasRoots[i] && !claimedStatus[i];
        }
    }

    // ==========================================
    // User Functions
    // ==========================================

    /**
     * @notice Claim tokens for specific round
     * @param _round Round number to claim for
     * @param _amount Amount of tokens to claim
     * @param _proof Merkle proof for the claim
     */
    function claim(
        uint256 _round,
        uint256 _amount,
        bytes32[] calldata _proof
    ) external whenNotPaused nonReentrant {
        if (_amount > MAX_CLAIM_AMOUNT) revert AmountTooLarge(_amount, MAX_CLAIM_AMOUNT);
        if (_amount == 0) revert ZeroAmountProvided();
        if (_round > maxAllowedRound) revert RoundNotExists(_round, maxAllowedRound);
        if (hasClaimed[_round][msg.sender]) revert AlreadyClaimedInRound(_round, msg.sender);
        if (merkleRoots[_round] == bytes32(0)) revert MerkleRootNotSet(_round);

        // Verify Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        if (!MerkleProof.verify(_proof, merkleRoots[_round], leaf)) {
            revert InvalidMerkleProof();
        }

        uint256 currentDay = block.timestamp / 1 days;
        uint256 dailyAvailable = dailyClaimLimit - dailyClaimed[currentDay];
        if (_amount > dailyAvailable) {
            revert DailyClaimLimitExceeded(_amount, dailyAvailable);
        }

        // Check contract has enough tokens
        uint256 contractBalance = vbiteToken.balanceOf(address(this));
        if (contractBalance < _amount) {
            revert InsufficientContractBalance(_amount, contractBalance);
        }

        // Mark as claimed and update statistics
        hasClaimed[_round][msg.sender] = true;
        totalClaimedPerRound[_round] += _amount;
        totalClaimedByUser[msg.sender] += _amount;
        totalClaimed += _amount;

        // Update daily claimed amount
        dailyClaimed[currentDay] += _amount;

        // Transfer tokens
        vbiteToken.safeTransfer(msg.sender, _amount);

        emit TokensClaimed(msg.sender, _round, _amount, totalClaimedByUser[msg.sender]);

        // Large claim monitoring
        if (_amount > 100_000 * 10**18) {
            emit LargeClaimAttempt(msg.sender, _round, _amount);
        }
    }

    /**
     * @notice Batch claim tokens for multiple rounds
     * @param _rounds Array of round numbers
     * @param _amounts Array of token amounts
     * @param _proofs Array of Merkle proofs
     */
    function batchClaim(
        uint256[] calldata _rounds,
        uint256[] calldata _amounts,
        bytes32[][] calldata _proofs
    ) external whenNotPaused nonReentrant {
        uint256 length = _rounds.length;
        if (length != _amounts.length || length != _proofs.length) {
            revert ArrayLengthMismatch();
        }
        
        if (length > MAX_BATCH_SIZE) revert TooManyBatchOperations(length, MAX_BATCH_SIZE);
        
        uint256 totalAmount = 0;

        // Verify all claims first
        for (uint256 i = 0; i < length; i++) {
            uint256 targetRound = _rounds[i];
            uint256 claimAmount = _amounts[i];
            
            if (claimAmount == 0) revert ZeroAmountProvided();
            if (targetRound > maxAllowedRound) revert RoundNotExists(targetRound, maxAllowedRound);
            if (hasClaimed[targetRound][msg.sender]) revert AlreadyClaimedInRound(targetRound, msg.sender);
            if (merkleRoots[targetRound] == bytes32(0)) revert MerkleRootNotSet(targetRound);

            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, claimAmount));
            if (!MerkleProof.verify(_proofs[i], merkleRoots[targetRound], leaf)) {
                revert InvalidMerkleProof();
            }

            uint256 newTotal = totalAmount + claimAmount;
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
            uint256 targetRound = _rounds[i];
            uint256 claimAmount = _amounts[i];

            hasClaimed[targetRound][msg.sender] = true;
            totalClaimedPerRound[targetRound] += claimAmount;
            totalClaimedByUser[msg.sender] += claimAmount;
            totalClaimed += claimAmount;

            emit TokensClaimed(msg.sender, targetRound, claimAmount, totalClaimedByUser[msg.sender]);
        }

        // Single token transfer
        vbiteToken.safeTransfer(msg.sender, totalAmount);
    }

    // ==========================================
    // Role Management Functions (Owner Only)
    // ==========================================

    /**
     * @notice Grant backend admin role to address
     * @param _account Address to grant role to
     */
    function grantBackendAdmin(address _account) external onlyOwner {
        if (_account == address(0)) revert ZeroAddressProvided();
        _grantRole(BACKEND_ADMIN_ROLE, _account);
        emit BackendAdminGranted(_account, msg.sender);
    }

    /**
     * @notice Revoke backend admin role from address
     * @param _account Address to revoke role from
     */
    function revokeBackendAdmin(address _account) external onlyOwner {
        _revokeRole(BACKEND_ADMIN_ROLE, _account);
        emit BackendAdminRevoked(_account, msg.sender);
    }

    /**
     * @notice Grant merkle setter role to address
     * @param _account Address to grant role to
     */
    function grantMerkleSetter(address _account) external onlyOwner {
        if (_account == address(0)) revert ZeroAddressProvided();
        _grantRole(MERKLE_SETTER_ROLE, _account);
        emit MerkleSetterGranted(_account, msg.sender);
    }

    /**
     * @notice Revoke merkle setter role from address
     * @param _account Address to revoke role from
     */
    function revokeMerkleSetter(address _account) external onlyOwner {
        _revokeRole(MERKLE_SETTER_ROLE, _account);
        emit MerkleSetterRevoked(_account, msg.sender);
    }

    /**
     * @notice Grant emergency role to address
     * @param _account Address to grant role to
     */
    function grantEmergencyRole(address _account) external onlyOwner {
        if (_account == address(0)) revert ZeroAddressProvided();
        _grantRole(EMERGENCY_ROLE, _account);
        emit EmergencyRoleGranted(_account, msg.sender);
    }

    /**
     * @notice Grant operator role to address
     * @param _account Address to grant role to
     */
    function grantOperatorRole(address _account) external onlyOwner {
        if (_account == address(0)) revert ZeroAddressProvided();
        _grantRole(OPERATOR_ROLE, _account);
        emit OperatorRoleGranted(_account, msg.sender);
    }

    // ==========================================
    // Backend Admin Functions
    // ==========================================

    /**
     * @notice Set Merkle root for specific round (Backend Admin)
     * @param _round Round number
     * @param _merkleRoot Merkle tree root hash
     */
    function setMerkleRootByBackend(uint256 _round, bytes32 _merkleRoot) external onlyMerkleSetter {
        if (_round > getCurrentRound()) revert RoundInFuture(_round, getCurrentRound());
        if (_merkleRoot == bytes32(0)) revert CannotSetZeroMerkleRoot();
        
        if (merkleRoots[_round] != bytes32(0)) {
            emit MerkleRootOverwritten(_round, merkleRoots[_round], _merkleRoot);
        }
        
        merkleRoots[_round] = _merkleRoot;
        
        if (_round > lastRoundWithRoot) {
            lastRoundWithRoot = _round;
        }
        if (_round > maxAllowedRound) {
            maxAllowedRound = _round;
        }

        emit MerkleRootSet(_round, _merkleRoot, msg.sender);
    }

    /**
     * @notice Set Merkle roots for multiple rounds (Backend Admin)
     * @param _rounds Array of round numbers
     * @param _merkleRootArray Array of Merkle roots
     */
    function setMerkleRootsBatchByBackend(
        uint256[] calldata _rounds,
        bytes32[] calldata _merkleRootArray
    ) external onlyMerkleSetter {
        if (_rounds.length != _merkleRootArray.length) {
            revert ArrayLengthMismatch();
        }

        uint256 currentRoundNum = getCurrentRound();
        uint256 maxRound = lastRoundWithRoot;
        uint256 newMaxAllowed = maxAllowedRound;

        for (uint256 i = 0; i < _rounds.length; i++) {
            uint256 targetRound = _rounds[i];
            if (targetRound > currentRoundNum) revert RoundInFuture(targetRound, currentRoundNum);
            if (_merkleRootArray[i] == bytes32(0)) revert CannotSetZeroMerkleRoot();
            
            merkleRoots[targetRound] = _merkleRootArray[i];
            
            if (targetRound > maxRound) {
                maxRound = targetRound;
            }
            if (targetRound > newMaxAllowed) {
                newMaxAllowed = targetRound;
            }

            emit MerkleRootSet(targetRound, _merkleRootArray[i], msg.sender);
        }

        lastRoundWithRoot = maxRound;
        if (newMaxAllowed > maxAllowedRound) {
            emit MaxAllowedRoundUpdated(maxAllowedRound, newMaxAllowed, msg.sender);
            maxAllowedRound = newMaxAllowed;
        }
    }

    /**
     * @notice Update daily claim limit (Operator)
     * @param _newLimit New daily claim limit
     */
    function updateDailyClaimLimitByOperator(uint256 _newLimit) external onlyOperator {
        emit DailyClaimLimitUpdated(dailyClaimLimit, _newLimit);
        dailyClaimLimit = _newLimit;
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
     * @param _round Round number
     * @param _merkleRoot Merkle tree root hash
     */
    function setMerkleRoot(uint256 _round, bytes32 _merkleRoot) external onlyOwner {
        if (_round > getCurrentRound()) revert RoundInFuture(_round, getCurrentRound());
        if (_merkleRoot == bytes32(0)) revert CannotSetZeroMerkleRoot();
        
        if (merkleRoots[_round] != bytes32(0)) {
            emit MerkleRootOverwritten(_round, merkleRoots[_round], _merkleRoot);
        }
        
        merkleRoots[_round] = _merkleRoot;
        
        if (_round > lastRoundWithRoot) {
            lastRoundWithRoot = _round;
        }
        if (_round > maxAllowedRound) {
            maxAllowedRound = _round;
        }

        emit MerkleRootSet(_round, _merkleRoot, msg.sender);
    }

    /**
     * @notice Set Merkle roots for multiple rounds (Owner)
     * @param _rounds Array of round numbers
     * @param _merkleRootArray Array of Merkle roots
     */
    function setMerkleRoots(
        uint256[] calldata _rounds,
        bytes32[] calldata _merkleRootArray
    ) external onlyOwner {
        if (_rounds.length != _merkleRootArray.length) {
            revert ArrayLengthMismatch();
        }

        uint256 currentRoundNum = getCurrentRound();
        uint256 maxRound = lastRoundWithRoot;
        uint256 newMaxAllowed = maxAllowedRound;

        for (uint256 i = 0; i < _rounds.length; i++) {
            uint256 targetRound = _rounds[i];
            if (targetRound > currentRoundNum) revert RoundInFuture(targetRound, currentRoundNum);
            
            merkleRoots[targetRound] = _merkleRootArray[i];
            
            if (targetRound > maxRound) {
                maxRound = targetRound;
            }
            if (targetRound > newMaxAllowed) {
                newMaxAllowed = targetRound;
            }

            emit MerkleRootSet(targetRound, _merkleRootArray[i], msg.sender);
        }

        lastRoundWithRoot = maxRound;
        if (newMaxAllowed > maxAllowedRound) {
            emit MaxAllowedRoundUpdated(maxAllowedRound, newMaxAllowed, msg.sender);
            maxAllowedRound = newMaxAllowed;
        }
    }

    /**
     * @notice Update max allowed round (Owner)
     * @param _newMaxRound New maximum round number
     */
    function updateMaxAllowedRound(uint256 _newMaxRound) external onlyOwner {
        if (_newMaxRound > getCurrentRound()) revert RoundInFuture(_newMaxRound, getCurrentRound());
        
        uint256 oldMaxRound = maxAllowedRound;
        maxAllowedRound = _newMaxRound;
        
        emit MaxAllowedRoundUpdated(oldMaxRound, _newMaxRound, msg.sender);
    }

    /**
     * @notice Deposit VBITE tokens to contract (Owner)
     * @param _amount Amount of tokens to deposit
     */
    function depositTokens(uint256 _amount) external onlyOwner {
        if (_amount == 0) revert ZeroAmountProvided();
        
        vbiteToken.safeTransferFrom(msg.sender, address(this), _amount);
        
        emit TokensDeposited(msg.sender, _amount, vbiteToken.balanceOf(address(this)));
    }

    /**
     * @notice Withdraw VBITE tokens from contract (Owner)
     * @param _amount Amount of tokens to withdraw
     */
    function withdrawTokens(uint256 _amount) external onlyOwner {
        if (_amount == 0) revert ZeroAmountProvided();
        
        uint256 contractBalance = vbiteToken.balanceOf(address(this));
        if (contractBalance < _amount) {
            revert InsufficientContractBalance(_amount, contractBalance);
        }
        
        vbiteToken.safeTransfer(msg.sender, _amount);
        
        emit TokensWithdrawn(msg.sender, _amount, vbiteToken.balanceOf(address(this)));
    }

    /**
     * @notice Update daily claim limit (Owner)
     * @param _newLimit New daily claim limit
     */
    function updateDailyClaimLimit(uint256 _newLimit) external onlyOwner {
        emit DailyClaimLimitUpdated(dailyClaimLimit, _newLimit);
        dailyClaimLimit = _newLimit;
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
     * @param _account Address to check
     * @return True if address has backend admin role
     */
    function isBackendAdmin(address _account) external view returns (bool) {
        return hasRole(BACKEND_ADMIN_ROLE, _account);
    }

    /**
     * @notice Check if address has merkle setter role
     * @param _account Address to check
     * @return True if address has merkle setter role
     */
    function isMerkleSetter(address _account) external view returns (bool) {
        return hasRole(MERKLE_SETTER_ROLE, _account);
    }

    /**
     * @notice Check if address has emergency role
     * @param _account Address to check
     * @return True if address has emergency role
     */
    function hasEmergencyRole(address _account) external view returns (bool) {
        return hasRole(EMERGENCY_ROLE, _account);
    }

    /**
     * @notice Check if address has operator role
     * @param _account Address to check
     * @return True if address has operator role
     */
    function isOperator(address _account) external view returns (bool) {
        return hasRole(OPERATOR_ROLE, _account);
    }

    /**
     * @notice Get all role members for a specific role
     * @param _role Role hash to query
     * @return count Number of members with this role
     */
    function getRoleMemberCount(bytes32 _role) external view returns (uint256 count) {
        return getRoleMemberCount(_role);
    }
}