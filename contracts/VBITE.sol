// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/utils/Pausable.sol";

/**
 * @title VBITE Token
 * @notice Utility token for the VivaBite platform
 */
contract VBITE is ERC20Burnable, Ownable, Pausable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;
    uint256 public constant INIT_SUPPLY = 725_000_000 * 1e18;

    error CapExceeded(uint256 requested, uint256 available);
    error ZeroAddressProvided();
    error ZeroAmountProvided();

    event ContractPaused(address account);
    event ContractUnpaused(address account);
    event TokensMinted(address to, uint256 amount);

    /**
     * @notice Creates VBITE token and releases initial supply to owner
     */
    constructor() ERC20("VivaBite Token", "VBITE") ERC20Burnable() Ownable(msg.sender) Pausable() {
        _mint(msg.sender, INIT_SUPPLY);
    }

    // ==========================================
    // Public and External Functions
    // ==========================================

    /**
     * @notice Mint new tokens (if needed in the future).
     * @dev Only callable by the owner, with a max supply cap.
     * @param to Token recipient address
     * @param amount Number of tokens for minting
     */
    function mintTokens(address to, uint256 amount)
    external onlyOwner
    {
        if(to == address(0)) revert ZeroAddressProvided();
        if(amount == 0) revert ZeroAmountProvided();

        uint256 currentSupply = totalSupply();
        uint256 availableToMint = MAX_SUPPLY - currentSupply;

        if(amount > availableToMint) {
            revert CapExceeded(amount, availableToMint);
        }

        _mint(to, amount);
        emit TokensMinted(to, amount);
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
      * @dev Reset _update to check the state of the pause
     */
    function _update(address from, address to, uint256 amount)
    internal virtual
    override whenNotPaused
    {
        super._update(from, to, amount);
    }

}
