// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/token/ERC721/ERC721.sol";
import "@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/utils/ReentrancyGuard.sol";
import "@openzeppelin/utils/Pausable.sol";
import "./VBITEAccessTypes.sol";


/**
 * @title AccessNFT
 * @notice NFT-access to the VivaBite platform: lifetime with soulbound logic
 */
contract VBITELifetimeNFT is ERC721, ERC721Enumerable, Ownable, Pausable, ReentrancyGuard
{
    using VBITEAccessTypes for VBITEAccessTypes.Tier;
    struct MintingStats {
        uint256 silverMinted;
        uint256 silverMax;
        uint256 goldMinted;
        uint256 goldMax;
        uint256 platinumMinted;
        uint256 platinumMax;
    }

    uint256 private _nextTokenId = 1;
    string private _baseTokenUri;

    mapping(uint256 => VBITEAccessTypes.Tier) public typeOf; // Tier per token
    mapping(VBITEAccessTypes.Tier => uint256) public totalMinted; // Total minted per tier
    mapping(VBITEAccessTypes.Tier => uint256) public maxSupply; // Max allowed per tier
    mapping(address => bool) public isMinter; // Minter role (e.g. crowdsale contract)
    mapping(address => mapping(VBITEAccessTypes.Tier => bool)) public minterTier;

    error ZeroAddressProvided();
    error InvalidTier(uint8 providedTier);
    error MinterNotAuthorized(address minter);
    error MinterNotAuthorizedForTier(address minter, VBITEAccessTypes.Tier tier);
    error MaxSupplyReached(VBITEAccessTypes.Tier tier);
    error SoulboundTransferAttempt(uint256 tokenId);

    modifier onlyMinter() {
        if (!isMinterForAnyTier(msg.sender)) {
            revert MinterNotAuthorized(msg.sender);
        }
        _;
    }

    event TokenMinted(uint256 indexed tokenId, address to, VBITEAccessTypes.Tier tier);
    event ContractPaused(address account);
    event ContractUnpaused(address account);

    constructor(address initialOwner) ERC721("VivaBite Lifetime NFT", "VB-NFT") Ownable(initialOwner) {
        maxSupply[VBITEAccessTypes.Tier.SILVER] = 100;
        maxSupply[VBITEAccessTypes.Tier.GOLD] = 100;
        maxSupply[VBITEAccessTypes.Tier.PLATINUM] = 50;
        maxSupply[VBITEAccessTypes.Tier.SPECIAL] = 0;
    }

    // ==========================================
    // Public and External Functions
    // ==========================================

    /**
     * @notice Returns the current minting statistics for all tiers
     * @return stats Structure containing minted and maximum supply for each tier
     */
    function getMintingStats() external view returns (MintingStats memory stats) {

        stats.silverMinted = totalMinted[VBITEAccessTypes.Tier.SILVER];
        stats.silverMax = maxSupply[VBITEAccessTypes.Tier.SILVER];
        stats.goldMinted = totalMinted[VBITEAccessTypes.Tier.GOLD];
        stats.goldMax = maxSupply[VBITEAccessTypes.Tier.GOLD];
        stats.platinumMinted = totalMinted[VBITEAccessTypes.Tier.PLATINUM];
        stats.platinumMax = maxSupply[VBITEAccessTypes.Tier.PLATINUM];

        return stats;
    }

    /**
     * @notice Checks if the contract supports a specific interface
     * @param interfaceId ID of the interface to check
     * @return Whether the interface is supported
     */
    function supportsInterface(bytes4 interfaceId)
    public view override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Checks if the user has a given level of NFT
     * @param owner User address to verify
     * @param tier NFT level for checking
     * @return true if the user has a NFT of this level
     */
    function hasNFT(address owner, VBITEAccessTypes.Tier tier)
    external view
    returns (bool)
    {
        uint256 balance = balanceOf(owner);

        if (balance == 0) return false;

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            if (typeOf[tokenId] == tier) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice Checks if the user has a NFT of this level or higher
     * @param owner User address to verify
     * @param tier Minimum NFT level to check
     * @return true if the user has this NFT or higher
     */
    function hasNFTOfTierOrHigher(address owner, VBITEAccessTypes.Tier tier)
    external view
    returns (bool)
    {
        uint256 balance = balanceOf(owner);

        if (balance == 0) return false;

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            if (uint8(typeOf[tokenId]) <= uint8(tier)) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice Returns the URI for a given token ID
     * @param tokenId The ID of the token to get the URI for
     * @return The token URI
     */
    function tokenURI(uint256 tokenId)
    public view override(ERC721)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @notice Checks if an address is a minter for any tier
     * @param account Address to check
     * @return Whether the address is a minter for any tier
     */
    function isMinterForAnyTier(address account)
    public view
    returns (bool)
    {
        return isMinter[account];
    }

    /**
     * @notice Returns the name for a given tier
     * @param tier The tier to get the name for
     * @return The name of the tier
     */
    function tierName(VBITEAccessTypes.Tier tier)
    public pure
    returns (string memory)
    {
        if (tier == VBITEAccessTypes.Tier.SILVER) return "Silver";
        if (tier == VBITEAccessTypes.Tier.GOLD) return "Gold";
        if (tier == VBITEAccessTypes.Tier.PLATINUM) return "Platinum";
        if (tier == VBITEAccessTypes.Tier.SPECIAL) return "Special";
        return "Unknown";
    }

    /**
     * @notice Mints a new lifetime NFT to the specified address
     * @param to Address to mint the token to
     * @param tier Tier of the token to mint
     */
    function mintLifetime(address to, VBITEAccessTypes.Tier tier)
    external whenNotPaused onlyMinter nonReentrant
    {
        if (to == address(0)) revert ZeroAddressProvided();
        if (tier > VBITEAccessTypes.Tier.SPECIAL) revert InvalidTier(uint8(tier));
        if (!minterTier[msg.sender][tier]) revert MinterNotAuthorizedForTier(msg.sender, tier);
        if (tier != VBITEAccessTypes.Tier.SPECIAL && totalMinted[tier] >= maxSupply[tier]) revert MaxSupplyReached(tier);

        uint256 tokenId = _nextTokenId++;
        typeOf[tokenId] = tier;

        if (tier != VBITEAccessTypes.Tier.SPECIAL) totalMinted[tier]++;

        _safeMint(to, tokenId);

        emit TokenMinted(tokenId, to, tier);
    }

    /**
     * @notice Sets the base URI for all tokens
     * @param uri New base URI
     */
    function setBaseURI(string calldata uri)
    external onlyOwner
    {
        _baseTokenUri = uri;
    }

    /**
     * @notice Adds a minter for specific tiers
     * @param account Address to add as minter
     * @param allowedTiers Array of tiers this minter is allowed to mint
     */
    function addMinter(address account, VBITEAccessTypes.Tier[] calldata allowedTiers)
    external onlyOwner
    {
        if (account == address(0)) {
            revert ZeroAddressProvided();
        }

        for (uint i = 0; i < allowedTiers.length; i++) {
            if (allowedTiers[i] > VBITEAccessTypes.Tier.SPECIAL) {
                revert InvalidTier(uint8(allowedTiers[i]));
            }
            minterTier[account][allowedTiers[i]] = true;
        }

        isMinter[account] = true;
    }

    /**
     * @notice Removes a minter for all tiers
     * @param account Address to remove minter role from
     */
    function delMinter(address account)
    external onlyOwner
    {
        if (account == address(0)) {
            revert ZeroAddressProvided();
        }

        for (uint8 i = 0; i <= uint8(VBITEAccessTypes.Tier.SPECIAL); i++) {
            minterTier[account][VBITEAccessTypes.Tier(i)] = false;
        }

        isMinter[account] = false;
    }

    /**
    * @notice Pause all token transfers.
     */
    function pause()
    external onlyOwner
    {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Resume all token transfers.
     */
    function unpause()
    external onlyOwner
    {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    // ==========================================
    // Internal Functions
    // ==========================================

    /**
     * @notice Updates token ownership
     * @dev Overrides the ERC721Enumerable _update function with soulbound logic for SPECIAL tier
     * @param to Address to transfer token to
     * @param tokenId ID of the token being transferred
     * @param auth Address authorized to make the transfer
     * @return from Previous owner of the token
     */
    function _update(address to, uint256 tokenId, address auth)
    internal
    override(ERC721, ERC721Enumerable)
    returns (address from)
    {
        from = super._update(to, tokenId, auth);

        if (from != address(0) && to != address(0) && typeOf[tokenId] == VBITEAccessTypes.Tier.SPECIAL) revert SoulboundTransferAttempt(tokenId);

        return from;
    }

    /**
     * @notice Increases the balance of an account
     * @dev Overrides the ERC721Enumerable _increaseBalance function
     * @param account Address to increase balance for
     * @param amount Amount to increase by
     */
    function _increaseBalance(address account, uint128 amount)
    internal override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, amount);
    }

    /**
     * @notice Returns the base URI for token metadata
     * @return Base URI string
     */
    function _baseURI()
    internal view override
    returns (string memory)
    {
        return _baseTokenUri;
    }
}
