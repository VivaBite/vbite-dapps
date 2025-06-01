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
 * @dev Each round lasts 1 day, admin sets Merkle roots, users claim once per round
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
    
    /// @notice Contract deployment timestamp (round 0 start)
    uint256 public immutable deploymentTime;
    
    /// @notice Last round for which Merkle root was set
    uint256 public lastRoundWithRoot;
    
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

    // ==========================================
    // Custom Errors
    // ==========================================

    error ZeroAddressProvided();
    error ZeroAmountProvided();
    error RoundNotActive(uint256 round);
    error InvalidMerkleProof();
    error AlreadyClaimedInRound(uint256 round, address user);
    error MerkleRootNotSet(uint256 round);
    error InsufficientContractBalance(uint256 required, uint256 available);
    error RoundInFuture(uint256 round, uint256 currentRound);
    error ArrayLengthMismatch();

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

    // ==========================================
    // Constructor
    // ==========================================

    /**
     * @notice Initialize airdrop contract
     * @param _vbiteToken Address of VBITE token contract
     * @param _owner Contract owner address
     */
    constructor(
        address _vbiteToken,
        address _owner
    ) Ownable(_owner) {
        if (_vbiteToken == address(0)) revert ZeroAddressProvided();
        if (_owner == address(0)) revert ZeroAddressProvided();
        
        vbiteToken = IERC20(_vbiteToken);
        deploymentTime = block.timestamp;
        // lastRoundWithRoot starts at 0 by default
    }

    // ==========================================
    // View Functions
    // ==========================================

    /**
     * @notice Get current round number based on time
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
     * @notice Get round start and end timestamps
     * @param round Round number
     * @return startTime Round start timestamp
     * @return endTime Round end timestamp
     */
    function getRoundTimes(uint256 round) external view returns (uint256 startTime, uint256 endTime) {
        startTime = deploymentTime + (round * ROUND_DURATION);
        endTime = startTime + ROUND_DURATION;
    }

    /**
     * @notice Check if round is currently active (time-based)
     * @param round Round number to check
     * @return True if round is active
     */
    function isRoundActive(uint256 round) public view returns (bool) {
        return round <= getCurrentRound();
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
     * @return isActive Whether round is currently active
     */
    function getUserInfo(address user, uint256 round) 
        external 
        view 
        returns (
            bool hasClaimed_, 
            bool hasRoot, 
            bool isActive
        ) 
    {
        hasClaimed_ = hasClaimed[round][user];
        hasRoot = merkleRoots[round] != bytes32(0);
        isActive = isRoundActive(round);
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
        if (amount == 0) revert ZeroAmountProvided();
        if (!isRoundActive(round)) revert RoundNotActive(round);
        if (hasClaimed[round][msg.sender]) revert AlreadyClaimedInRound(round, msg.sender);
        if (merkleRoots[round] == bytes32(0)) revert MerkleRootNotSet(round);

        // Verify Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        if (!MerkleProof.verify(proof, merkleRoots[round], leaf)) {
            revert InvalidMerkleProof();
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

        // Transfer tokens
        vbiteToken.safeTransfer(msg.sender, amount);

        emit TokensClaimed(msg.sender, round, amount, totalClaimedByUser[msg.sender]);
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

        uint256 totalAmount = 0;

        // Verify all claims first
        for (uint256 i = 0; i < length; i++) {
            uint256 round = rounds[i];
            uint256 amount = amounts[i];
            
            if (amount == 0) revert ZeroAmountProvided();
            if (!isRoundActive(round)) revert RoundNotActive(round);
            if (hasClaimed[round][msg.sender]) revert AlreadyClaimedInRound(round, msg.sender);
            if (merkleRoots[round] == bytes32(0)) revert MerkleRootNotSet(round);

            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
            if (!MerkleProof.verify(proofs[i], merkleRoots[round], leaf)) {
                revert InvalidMerkleProof();
            }

            totalAmount += amount;
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
    function setMerkleRoot(
        uint256 round,
        bytes32 merkleRoot
    ) external onlyOwner {
        if (round > getCurrentRound()) revert RoundInFuture(round, getCurrentRound());
        
        merkleRoots[round] = merkleRoot;
        
        // Update last round with root if this is newer
        if (round > lastRoundWithRoot) {
            lastRoundWithRoot = round;
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

        for (uint256 i = 0; i < rounds.length; i++) {
            uint256 round = rounds[i];
            if (round > currentRoundNum) revert RoundInFuture(round, currentRoundNum);
            
            merkleRoots[round] = merkleRootArray[i];
            
            if (round > maxRound) {
                maxRound = round;
            }

            emit MerkleRootSet(round, merkleRootArray[i], msg.sender);
        }

        lastRoundWithRoot = maxRound;
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