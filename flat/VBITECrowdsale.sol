// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// dependencies/smartcontractkit-chainlink-brownie-contracts-1.3.0/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol

// solhint-disable-next-line interface-starts-with-i
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// dependencies/@openzeppelin-contracts-5.3.0/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// dependencies/@openzeppelin-contracts-5.3.0/utils/Errors.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/Errors.sol)

/**
 * @dev Collection of common custom errors used in multiple contracts
 *
 * IMPORTANT: Backwards compatibility is not guaranteed in future versions of the library.
 * It is recommended to avoid relying on the error API for critical functionality.
 *
 * _Available since v5.1._
 */
library Errors {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error InsufficientBalance(uint256 balance, uint256 needed);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedCall();

    /**
     * @dev The deployment failed.
     */
    error FailedDeployment();

    /**
     * @dev A necessary precompile is missing.
     */
    error MissingPrecompile(address);
}

// dependencies/@openzeppelin-contracts-5.3.0/access/IAccessControl.sol

// OpenZeppelin Contracts (last updated v5.3.0) (access/IAccessControl.sol)

/**
 * @dev External interface of AccessControl declared to support ERC-165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted to signal this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call. This account bears the admin role (for the granted role).
     * Expected in cases where the role was granted using the internal {AccessControl-_grantRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

// dependencies/@openzeppelin-contracts-5.3.0/utils/introspection/IERC165.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// dependencies/@openzeppelin-contracts-5.3.0/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// dependencies/@openzeppelin-contracts-5.3.0/token/ERC721/IERC721Receiver.sol

// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC721/IERC721Receiver.sol)

/**
 * @title ERC-721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC-721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// dependencies/@openzeppelin-contracts-5.3.0/utils/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// contracts/VBITEAccessTypes.sol

library VBITEAccessTypes {
    enum Tier {
        SILVER,
        GOLD,
        PLATINUM,
        SPECIAL
    }
}

// dependencies/@openzeppelin-contracts-5.3.0/utils/Address.sol

// OpenZeppelin Contracts (last updated v5.2.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert Errors.InsufficientBalance(address(this).balance, amount);
        }

        (bool success, bytes memory returndata) = recipient.call{value: amount}("");
        if (!success) {
            _revert(returndata);
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {Errors.FailedCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert Errors.InsufficientBalance(address(this).balance, value);
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {Errors.FailedCall}) in case
     * of an unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {Errors.FailedCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {Errors.FailedCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            assembly ("memory-safe") {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert Errors.FailedCall();
        }
    }
}

// dependencies/@openzeppelin-contracts-5.3.0/utils/introspection/ERC165.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/introspection/ERC165.sol)

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC-165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// dependencies/@openzeppelin-contracts-5.3.0/token/ERC721/utils/ERC721Holder.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/utils/ERC721Holder.sol)

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or
 * {IERC721-setApprovalForAll}.
 */
abstract contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// dependencies/@openzeppelin-contracts-5.3.0/token/ERC1155/IERC1155Receiver.sol

// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC1155/IERC1155Receiver.sol)

/**
 * @dev Interface that must be implemented by smart contracts in order to receive
 * ERC-1155 token transfers.
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC-1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC-1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// dependencies/@openzeppelin-contracts-5.3.0/interfaces/IERC165.sol

// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC165.sol)

// dependencies/@openzeppelin-contracts-5.3.0/interfaces/IERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

// dependencies/@openzeppelin-contracts-5.3.0/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// dependencies/@openzeppelin-contracts-5.3.0/utils/Pausable.sol

// OpenZeppelin Contracts (last updated v5.3.0) (utils/Pausable.sol)

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// dependencies/@openzeppelin-contracts-5.3.0/token/ERC1155/utils/ERC1155Holder.sol

// OpenZeppelin Contracts (last updated v5.1.0) (token/ERC1155/utils/ERC1155Holder.sol)

/**
 * @dev Simple implementation of `IERC1155Receiver` that will allow a contract to hold ERC-1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 */
abstract contract ERC1155Holder is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// dependencies/@openzeppelin-contracts-5.3.0/access/AccessControl.sol

// OpenZeppelin Contracts (last updated v5.3.0) (access/AccessControl.sol)

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 role => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` from `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// dependencies/@openzeppelin-contracts-5.3.0/interfaces/IERC1363.sol

// OpenZeppelin Contracts (last updated v5.1.0) (interfaces/IERC1363.sol)

/**
 * @title IERC1363
 * @dev Interface of the ERC-1363 standard as defined in the https://eips.ethereum.org/EIPS/eip-1363[ERC-1363].
 *
 * Defines an extension interface for ERC-20 tokens that supports executing code on a recipient contract
 * after `transfer` or `transferFrom`, or code on a spender contract after `approve`, in a single transaction.
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0xb0202a11.
     * 0xb0202a11 ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}

// dependencies/@openzeppelin-contracts-5.3.0/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v5.3.0) (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC-20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    /**
     * @dev An operation with an ERC-20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Variant of {safeTransfer} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransfer(IERC20 token, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Variant of {safeTransferFrom} that returns a bool instead of reverting if the operation is not successful.
     */
    function trySafeTransferFrom(IERC20 token, address from, address to, uint256 value) internal returns (bool) {
        return _callOptionalReturnBool(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     *
     * IMPORTANT: If the token implements ERC-7674 (ERC-20 with temporary allowance), and if the "client"
     * smart contract uses ERC-7674 to set temporary allowances, then the "client" smart contract should avoid using
     * this function. Performing a {safeIncreaseAllowance} or {safeDecreaseAllowance} operation on a token contract
     * that has a non-zero temporary allowance (for that particular owner-spender) will result in unexpected behavior.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     *
     * NOTE: If the token implements ERC-7674, this function will not modify any temporary allowance. This function
     * only sets the "standard" allowance. Any temporary allowance will remain active, in addition to the value being
     * set here.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Performs an {ERC1363} transferAndCall, with a fallback to the simple {ERC20} transfer if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            safeTransfer(token, to, value);
        } else if (!token.transferAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferFromAndCall, with a fallback to the simple {ERC20} transferFrom if the target
     * has no code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferFromAndCallRelaxed(
        IERC1363 token,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransferFrom(token, from, to, value);
        } else if (!token.transferFromAndCall(from, to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} approveAndCall, with a fallback to the simple {ERC20} approve if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * NOTE: When the recipient address (`to`) has no code (i.e. is an EOA), this function behaves as {forceApprove}.
     * Opposedly, when the recipient address (`to`) has code, this function only attempts to call {ERC1363-approveAndCall}
     * once without retrying, and relies on the returned value to be true.
     *
     * Reverts if the returned value is other than `true`.
     */
    function approveAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            forceApprove(token, to, value);
        } else if (!token.approveAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturnBool} that reverts if call fails to meet the requirements.
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            let success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            // bubble errors
            if iszero(success) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
            returnSize := returndatasize()
            returnValue := mload(0)
        }

        if (returnSize == 0 ? address(token).code.length == 0 : returnValue != 1) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silently catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly ("memory-safe") {
            success := call(gas(), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0)
        }
        return success && (returnSize == 0 ? address(token).code.length > 0 : returnValue == 1);
    }
}

// dependencies/@openzeppelin-contracts-5.3.0/governance/TimelockController.sol

// OpenZeppelin Contracts (last updated v5.3.0) (governance/TimelockController.sol)

/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 */
contract TimelockController is AccessControl, ERC721Holder, ERC1155Holder {
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 id => uint256) private _timestamps;
    uint256 private _minDelay;

    enum OperationState {
        Unset,
        Waiting,
        Ready,
        Done
    }

    /**
     * @dev Mismatch between the parameters length for an operation call.
     */
    error TimelockInvalidOperationLength(uint256 targets, uint256 payloads, uint256 values);

    /**
     * @dev The schedule operation doesn't meet the minimum delay.
     */
    error TimelockInsufficientDelay(uint256 delay, uint256 minDelay);

    /**
     * @dev The current state of an operation is not as required.
     * The `expectedStates` is a bitmap with the bits enabled for each OperationState enum position
     * counting from right to left.
     *
     * See {_encodeStateBitmap}.
     */
    error TimelockUnexpectedOperationState(bytes32 operationId, bytes32 expectedStates);

    /**
     * @dev The predecessor to an operation not yet done.
     */
    error TimelockUnexecutedPredecessor(bytes32 predecessorId);

    /**
     * @dev The caller account is not authorized.
     */
    error TimelockUnauthorizedCaller(address caller);

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when new proposal is scheduled with non-zero salt.
     */
    event CallSalt(bytes32 indexed id, bytes32 salt);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with the following parameters:
     *
     * - `minDelay`: initial minimum delay in seconds for operations
     * - `proposers`: accounts to be granted proposer and canceller roles
     * - `executors`: accounts to be granted executor role
     * - `admin`: optional account to be granted admin role; disable with zero address
     *
     * IMPORTANT: The optional admin can aid with initial configuration of roles after deployment
     * without being subject to delay, but this role should be subsequently renounced in favor of
     * administration through timelocked proposals. Previous versions of this contract would assign
     * this admin to the deployer automatically and should be renounced as well.
     */
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors, address admin) {
        // self administration
        _grantRole(DEFAULT_ADMIN_ROLE, address(this));

        // optional admin
        if (admin != address(0)) {
            _grantRole(DEFAULT_ADMIN_ROLE, admin);
        }

        // register proposers and cancellers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _grantRole(PROPOSER_ROLE, proposers[i]);
            _grantRole(CANCELLER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _grantRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable virtual {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl, ERC1155Holder) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns whether an id corresponds to a registered operation. This
     * includes both Waiting, Ready, and Done operations.
     */
    function isOperation(bytes32 id) public view returns (bool) {
        return getOperationState(id) != OperationState.Unset;
    }

    /**
     * @dev Returns whether an operation is pending or not. Note that a "pending" operation may also be "ready".
     */
    function isOperationPending(bytes32 id) public view returns (bool) {
        OperationState state = getOperationState(id);
        return state == OperationState.Waiting || state == OperationState.Ready;
    }

    /**
     * @dev Returns whether an operation is ready for execution. Note that a "ready" operation is also "pending".
     */
    function isOperationReady(bytes32 id) public view returns (bool) {
        return getOperationState(id) == OperationState.Ready;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view returns (bool) {
        return getOperationState(id) == OperationState.Done;
    }

    /**
     * @dev Returns the timestamp at which an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256) {
        return _timestamps[id];
    }

    /**
     * @dev Returns operation state.
     */
    function getOperationState(bytes32 id) public view virtual returns (OperationState) {
        uint256 timestamp = getTimestamp(id);
        if (timestamp == 0) {
            return OperationState.Unset;
        } else if (timestamp == _DONE_TIMESTAMP) {
            return OperationState.Done;
        } else if (timestamp > block.timestamp) {
            return OperationState.Waiting;
        } else {
            return OperationState.Ready;
        }
    }

    /**
     * @dev Returns the minimum delay in seconds for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32) {
        return keccak256(abi.encode(targets, values, payloads, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits {CallSalt} if salt is nonzero, and {CallScheduled}.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
        if (salt != bytes32(0)) {
            emit CallSalt(id, salt);
        }
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits {CallSalt} if salt is nonzero, and one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        if (targets.length != values.length || targets.length != payloads.length) {
            revert TimelockInvalidOperationLength(targets.length, payloads.length, values.length);
        }

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], payloads[i], predecessor, delay);
        }
        if (salt != bytes32(0)) {
            emit CallSalt(id, salt);
        }
    }

    /**
     * @dev Schedule an operation that is to become valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        if (isOperation(id)) {
            revert TimelockUnexpectedOperationState(id, _encodeStateBitmap(OperationState.Unset));
        }
        uint256 minDelay = getMinDelay();
        if (delay < minDelay) {
            revert TimelockInsufficientDelay(delay, minDelay);
        }
        _timestamps[id] = block.timestamp + delay;
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'canceller' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(CANCELLER_ROLE) {
        if (!isOperationPending(id)) {
            revert TimelockUnexpectedOperationState(
                id,
                _encodeStateBitmap(OperationState.Waiting) | _encodeStateBitmap(OperationState.Ready)
            );
        }
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    // This function can reenter, but it doesn't pose a risk because _afterCall checks that the proposal is pending,
    // thus any modifications to the operation during reentrancy should be caught.
    // slither-disable-next-line reentrancy-eth
    function execute(
        address target,
        uint256 value,
        bytes calldata payload,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, payload, predecessor, salt);

        _beforeCall(id, predecessor);
        _execute(target, value, payload);
        emit CallExecuted(id, 0, target, value, payload);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    // This function can reenter, but it doesn't pose a risk because _afterCall checks that the proposal is pending,
    // thus any modifications to the operation during reentrancy should be caught.
    // slither-disable-next-line reentrancy-eth
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        if (targets.length != values.length || targets.length != payloads.length) {
            revert TimelockInvalidOperationLength(targets.length, payloads.length, values.length);
        }

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);

        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            address target = targets[i];
            uint256 value = values[i];
            bytes calldata payload = payloads[i];
            _execute(target, value, payload);
            emit CallExecuted(id, i, target, value, payload);
        }
        _afterCall(id);
    }

    /**
     * @dev Execute an operation's call.
     */
    function _execute(address target, uint256 value, bytes calldata data) internal virtual {
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        Address.verifyCallResult(success, returndata);
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        if (!isOperationReady(id)) {
            revert TimelockUnexpectedOperationState(id, _encodeStateBitmap(OperationState.Ready));
        }
        if (predecessor != bytes32(0) && !isOperationDone(predecessor)) {
            revert TimelockUnexecutedPredecessor(predecessor);
        }
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        if (!isOperationReady(id)) {
            revert TimelockUnexpectedOperationState(id, _encodeStateBitmap(OperationState.Ready));
        }
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        address sender = _msgSender();
        if (sender != address(this)) {
            revert TimelockUnauthorizedCaller(sender);
        }
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }

    /**
     * @dev Encodes a `OperationState` into a `bytes32` representation where each bit enabled corresponds to
     * the underlying position in the `OperationState` enum. For example:
     *
     * 0x000...1000
     *   ^^^^^^----- ...
     *         ^---- Done
     *          ^--- Ready
     *           ^-- Waiting
     *            ^- Unset
     */
    function _encodeStateBitmap(OperationState operationState) internal pure returns (bytes32) {
        return bytes32(1 << uint8(operationState));
    }
}

// contracts/VBITECrowdsale.sol

interface IVBITELifetimeNFT {
    function totalMinted(VBITEAccessTypes.Tier tier) external view returns (uint256);
    function maxSupply(VBITEAccessTypes.Tier tier) external view returns (uint256);
    function mintLifetime(address to, VBITEAccessTypes.Tier tier) external;
    function hasNFT(address owner, VBITEAccessTypes.Tier tier) external view returns (bool);
    function hasNFTOfTierOrHigher(address owner, VBITEAccessTypes.Tier tier) external view returns (bool);
}

/**
 * @title VBITECrowdsale
 * @notice Accepts payment in multiple currencies (MATIC, USDC, ETH) and issues VBITE according to the exchange rate to USD.
 * @dev Includes price oracle caching, NFT bonuses, and price anomaly detection. Protected against common threats
 * including reentrancy, frontrunning (via deadline), and price manipulation (via slippage protection).
 */
contract VBITECrowdsale is Ownable, ReentrancyGuard, Pausable {
    using VBITEAccessTypes for VBITEAccessTypes.Tier;
    using SafeERC20 for IERC20;
    using Address for address payable;

    /**
     * @notice Purchase preview data structure with information about potential purchase
     */
    struct PurchasePreview {
        bool paymentTokenAccepted;     // Whether the token is accepted for payments
        uint256 vbiteAmount;           // Amount of VBITE tokens to receive
        address paymentToken;          // Address of the payment token
        uint256 paymentAmount;         // Amount of payment tokens required
        bool willGetSilver;            // Flag indicating if user will receive Silver NFT
        bool willGetGold;              // Flag indicating if user will receive Gold NFT
        bool willGetPlatinum;          // Flag indicating if user will receive Platinum NFT
        bool bonusAvailable;           // Flag indicating if NFT bonus is available
    }

    /**
     * @notice Token configuration structure
     */
    struct TokenConfig {
        bool accepted;                    // Whether the token is accepted
        uint8 decimals;                   // Number of decimals for the token
        AggregatorV3Interface priceFeed;  // Price feed for the token
    }

    /**
     * @notice Oracle cache structure for price data
     */
    struct OracleCache {
        int256 price;                  // Cached price value
        uint256 updatedAt;             // Timestamp when the price was updated
        uint80 roundId;                // Round ID from the oracle
        uint80 answeredInRound;        // Round that answered this price, used to detect stale data
    }

    // Threshold constants
    uint256 public constant SILVER_THRESHOLD = 24_000e18;
    uint256 public constant GOLD_THRESHOLD = 48_000e18;
    uint256 public constant PLATINUM_THRESHOLD = 120_000e18;
    address public constant NATIVE_TOKEN = address(0);
    uint256 public initialVbiteAllocation;

    // TimelockController
    uint256 public constant MIN_TIMELOCK_DELAY = 1 days; // Минимальная задержка 1 день
    TimelockController public timelock;

    // Custom errors
    error AlreadyInitialized();
    error CalculationOverflow(string operation);
    error DeviationTooHigh(uint256 provided, uint256 maxAllowed);
    error InsufficientVBITEBalance(uint256 required, uint256 available);
    error InvalidDecimals();
    error InvalidOracleDelay();
    error NFTMintFailure(address recipient, VBITEAccessTypes.Tier tier);
    error OnlyTimelockAllowed();
    error OperationAlreadyExecuted();
    error OperationNotReady();
    error OracleDataInvalid(string reason);
    error PaymentFailed();
    error SlippageTooHigh(uint256 minVbiteAmount, uint256 vbiteAmount);
    error TokenAlreadyAccepted(address token);
    error TokenAlreadyHasHigherTier(address user, VBITEAccessTypes.Tier currentTier, VBITEAccessTypes.Tier newTier);
    error TokenCannotBeRecovered(address token);
    error TokenNotAccepted(address token);
    error TransactionExpired();
    error TransferFailed();
    error ZeroAddressProvided();
    error ZeroPriceFeedProvided();
    error ZeroRateProvided();
    error ZeroValueSent();

    IERC20 public immutable vbite;
    IVBITELifetimeNFT public lifetimeNFT;
    uint256 public maxOracleDelay = 24 hours;
    uint256 public maxPriceDeviation = 10;
    address public treasury;
    uint256 public rate;
    address[] public activeTokens;
    mapping(address => bool) private isActiveToken;
    mapping(address => TokenConfig) public tokens;
    mapping(address => OracleCache) public oracleCache;

    // To track expected changes
    address public pendingTreasury;
    uint256 public pendingRate;

    event AllOracleCachesUpdated(uint256 timestamp, uint256 count);
    event AnomalyDetected(address token, int256 oldPrice, int256 newPrice, uint256 percentChange);
    event ContractPaused(address account);
    event ContractUnpaused(address account);
    event NFTGrantFailure(address indexed user, bytes reason);
    event NFTGranted(address indexed buyer, VBITEAccessTypes.Tier tier, uint256 vbiteAmount);
    event OracleCacheUpdated(address indexed token, int256 price, uint256 updatedAt);
    event RateChangeRequested(uint256 currentRate, uint256 pendingRate);
    event RateChanged(uint256 oldRate, uint256 newRate);
    event TokenConfigSet(address indexed token, uint8 decimals, address priceFeed, bool accepted);
    event TokensPurchased(address indexed buyer, address paymentToken, uint256 paymentAmount, uint256 vbiteAmount);
    event TreasuryChangeRequested(address currentTreasury, address pendingTreasury);
    event TreasuryChanged(address oldTreasury, address newTreasury);

    /**
     * @notice Creates a crowdsale with specified parameters
     * @param _owner Contract owner address
     * @param _vbite VBITE token address
     * @param _treasury Treasury address for collecting funds
     * @param _rate Exchange rate (VBITE per 1 USD * 10^8)
     * @param _lifetimeNFT NFT Contract address
     * @param _proposers Addresses allowed to create timelock proposals
     * @param _executors Addresses allowed to execute timelock proposals
     */
    constructor(
        address _owner,
        address _vbite,
        address _treasury,
        uint256 _rate,
        address _lifetimeNFT,
        address[] memory _proposers,
        address[] memory _executors
    ) Ownable(_owner) {
        if(_vbite == address(0)) revert ZeroAddressProvided();
        if(_treasury == address(0)) revert ZeroAddressProvided();
        if(_rate == 0) revert ZeroRateProvided();
        if(_lifetimeNFT == address(0)) revert ZeroAddressProvided();

        vbite = IERC20(_vbite);
        treasury = _treasury;
        rate = _rate;
        lifetimeNFT = IVBITELifetimeNFT(_lifetimeNFT);

        // Initializing TimelockController
        timelock = new TimelockController(
            MIN_TIMELOCK_DELAY,
            _proposers,
            _executors,
            address(0) // admin (0 = нет админа)
        );
    }

    // ==========================================
    // Public and External Functions
    // ==========================================

    /**
     * @notice Sets the initial amount of VBITE tokens available for the crowdsale
     * @dev Can only be called once; subsequent attempts will be rejected
     * @param amount The amount of tokens to be distributed through the crowdsale
     */
    function setInitialVbiteAllocation(uint256 amount) external onlyOwner {
        if (initialVbiteAllocation > 0) revert AlreadyInitialized();
        initialVbiteAllocation = amount;
    }

    /**
     * @notice Adds a new token to the list of accepted tokens
     * @param token Token address (0 for native network token)
     * @param decimals Number of decimal places in the token
     * @param priceFeed Address of the Chainlink price oracle
     */
    function addAcceptedToken(address token, uint8 decimals, address priceFeed) external onlyOwner nonReentrant {
        if(tokens[token].accepted) revert TokenAlreadyAccepted(token);
        if(priceFeed == address(0)) revert ZeroPriceFeedProvided();
        if(decimals == 0) revert InvalidDecimals();

        tokens[token] = TokenConfig({
            accepted: true,
            decimals: decimals,
            priceFeed: AggregatorV3Interface(priceFeed)
        });

        if (!isActiveToken[token]) {
            activeTokens.push(token);
            isActiveToken[token] = true;
        }

        emit TokenConfigSet(token, decimals, priceFeed, true);
    }

    /**
     * @notice Removes a token from the payment list
     * @param token Token address to be removed
     */
    function removeAcceptedToken(address token) external onlyOwner nonReentrant {
        if(!tokens[token].accepted) revert TokenNotAccepted(token);
        tokens[token].accepted = false;

        for (uint i = 0; i < activeTokens.length; i++) {
            if (activeTokens[i] == token) {
                activeTokens[i] = activeTokens[activeTokens.length - 1];
                activeTokens.pop();
                break;
            }
        }

        isActiveToken[token] = false;

        emit TokenConfigSet(token, tokens[token].decimals, address(tokens[token].priceFeed), false);
    }

    /**
     * @notice Updates settings for an accepted token
     * @param token Token address to update
     * @param decimals New number of decimal places
     * @param priceFeed New price oracle address
     * @param isAccepted Flag indicating if token is accepted
     */
    function updateTokenConfig(address token, uint8 decimals, address priceFeed, bool isAccepted) external onlyOwner nonReentrant {
        if(priceFeed == address(0)) revert ZeroPriceFeedProvided();
        if(decimals == 0) revert InvalidDecimals();

        tokens[token] = TokenConfig({
            accepted: isAccepted,
            decimals: decimals,
            priceFeed: AggregatorV3Interface(priceFeed)
        });

        if (isAccepted && !isActiveToken[token]) {
            activeTokens.push(token);
            isActiveToken[token] = true;
        } else if (!isAccepted && isActiveToken[token]) {
            for (uint i = 0; i < activeTokens.length; i++) {
                if (activeTokens[i] == token) {
                    activeTokens[i] = activeTokens[activeTokens.length - 1];
                    activeTokens.pop();
                    break;
                }
            }
        }

        if (isAccepted) {
            _updateOracleCache(token);
        }

        emit TokenConfigSet(token, decimals, priceFeed, isAccepted);
    }

    /**
     * @notice Requests a change of treasury address (via timelock)
     * @param newTreasury New treasury address
     */
    function requestTreasuryChange(address newTreasury) external onlyOwner {
        if(newTreasury == address(0)) revert ZeroAddressProvided();
        pendingTreasury = newTreasury;

        // Create a deferred transaction via timelock
        bytes memory data = abi.encodeWithSelector(
            this.executeTreasuryChange.selector,
            newTreasury
        );

        timelock.schedule(
            address(this),
            0, // value
            data,
            bytes32(0), // predecessor
            bytes32(0), // salt
            MIN_TIMELOCK_DELAY
        );

        emit TreasuryChangeRequested(treasury, newTreasury);
    }

    /**
     * @notice Executes treasury address change (only via timelock)
     * @param newTreasury New treasury address
     */
    function executeTreasuryChange(address newTreasury) external {
        if(msg.sender != address(timelock)) revert OnlyTimelockAllowed();
        if(newTreasury != pendingTreasury) revert ZeroAddressProvided();

        // Проверка что операция действительно была запланирована через timelock
        bytes32 id = keccak256(abi.encode(
            address(this),
            0, // value
            abi.encodeWithSelector(this.executeTreasuryChange.selector, newTreasury),
            bytes32(0), // predecessor
            bytes32(0)  // salt
        ));

        if (!timelock.isOperationReady(id)) {
            revert OperationNotReady();
        }
        if (timelock.isOperationDone(id)) {
            revert  OperationAlreadyExecuted();
        }

        address oldTreasury = treasury;
        treasury = newTreasury;
        pendingTreasury = address(0);

        emit TreasuryChanged(oldTreasury, newTreasury);
    }

    /**
     * @notice Requests a VBITE rate change (via timelock)
     * @param newRate New exchange rate
     */
    function requestRateChange(uint256 newRate) external onlyOwner {
        if(newRate == 0) revert ZeroRateProvided();
        pendingRate = newRate;

        // Create a deferred transaction via timelock
        bytes memory data = abi.encodeWithSelector(
            this.executeRateChange.selector,
            newRate
        );

        timelock.schedule(
            address(this),
            0, // value
            data,
            bytes32(0), // predecessor
            bytes32(0), // salt
            MIN_TIMELOCK_DELAY
        );

        emit RateChangeRequested(rate, newRate);
    }

    /**
     * @notice Executes rate change (only via timelock)
     * @param newRate New exchange rate
     */
    function executeRateChange(uint256 newRate) external {
        if(msg.sender != address(timelock)) revert OnlyTimelockAllowed();
        if(newRate != pendingRate) revert ZeroRateProvided();

        bytes32 id = keccak256(abi.encode(
            address(this),
            0, // value
            abi.encodeWithSelector(this.executeRateChange.selector, newRate),
            bytes32(0), // predecessor
            bytes32(0)  // salt
        ));

        if (!timelock.isOperationReady(id)) {
            revert OperationNotReady();
        }
        if (timelock.isOperationDone(id)) {
            revert OperationAlreadyExecuted();
        }

        uint256 oldRate = rate;
        rate = newRate;
        pendingRate = 0;

        emit RateChanged(oldRate, newRate);
    }

    /**
     * @notice Sets maximum allowable oracle data delay
     * @param newDelay New delay value in seconds
     */
    function setMaxOracleDelay(uint256 newDelay) external onlyOwner {
        if(newDelay == 0) revert InvalidOracleDelay();
        maxOracleDelay = newDelay;
    }

    /**
     * @notice Sets maximum allowable price deviation percentage before triggering anomaly detection
     * @param newDeviation New deviation percentage (1-50)
     */
    function setMaxPriceDeviation(uint256 newDeviation) external onlyOwner {
        if (newDeviation > 50) revert DeviationTooHigh(newDeviation, 50);
        maxPriceDeviation = newDeviation;
    }

    /**
     * @notice Purchases VBITE for the specified ERC20 token
     * @param token Token address for payment
     * @param amount Amount of tokens to pay
     * @param minVbiteAmount Minimum amount of VBITE to receive (slippage protection)
     * @param deadline Transaction deadline timestamp
     * @return vbiteAmount Amount of VBITE tokens received
     */
    function buyWithToken(address token, uint256 amount, uint256 minVbiteAmount, uint256 deadline)
    external nonReentrant whenNotPaused returns (uint256 vbiteAmount) {
        if (block.timestamp > deadline) revert TransactionExpired();
        if(!tokens[token].accepted) revert TokenNotAccepted(token);

        IERC20(token).safeTransferFrom(msg.sender, treasury, amount);

        vbiteAmount = _calculateAndTransferVBITE(msg.sender, token, amount);

        if (vbiteAmount < minVbiteAmount) revert SlippageTooHigh(minVbiteAmount, vbiteAmount);

        return vbiteAmount;
    }

    /**
     * @notice Purchases VBITE for native network token (MATIC)
     * @param minVbiteAmount Minimum amount of VBITE to receive (slippage protection)
     * @param deadline Transaction deadline timestamp
     * @return vbiteAmount Amount of VBITE tokens received
     */
    function buyWithMatic(uint256 minVbiteAmount, uint256 deadline)
    external payable nonReentrant whenNotPaused returns (uint256 vbiteAmount) {
        if (block.timestamp > deadline) revert TransactionExpired();
        if(!tokens[NATIVE_TOKEN].accepted) revert TokenNotAccepted(NATIVE_TOKEN);
        if(msg.value == 0) revert ZeroValueSent();

        payable(treasury).sendValue(msg.value);

        vbiteAmount = _calculateAndTransferVBITE(msg.sender, address(0), msg.value);

        if (vbiteAmount < minVbiteAmount) revert SlippageTooHigh(minVbiteAmount, vbiteAmount);

        return vbiteAmount;
    }

    /**
     * @notice Recovers accidentally sent ERC20 tokens (except VBITE)
     * @param tokenAddress Token address to recover
     * @param amount Amount of tokens to recover
     */
    function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        if(tokenAddress == address(vbite)) revert TokenCannotBeRecovered(tokenAddress);
        if(tokens[tokenAddress].accepted) revert TokenCannotBeRecovered(tokenAddress);

        IERC20(tokenAddress).safeTransfer(owner(), amount);
    }

    /**
     * @notice Recovers accidentally sent native tokens
     * @dev Only callable by the owner, transfers all native tokens to owner address
     */
    function recoverETH() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).sendValue(balance);
        }
    }

    /**
     * @notice Calculates the amount of VBITE for a given payment amount
     * @param paymentToken Payment token address
     * @param paymentAmount Amount of payment tokens
     * @return Preview structure with purchase details
     */
    function previewSpendAmount(address paymentToken, uint256 paymentAmount) public view returns (PurchasePreview memory) {
        // Checking the availability of token for payment
        TokenConfig memory tokenConfig = tokens[paymentToken];
        bool accepted = tokenConfig.accepted;

        if (!accepted || paymentAmount == 0) {
            return PurchasePreview(false, 0, paymentToken, 0, false, false, false, false);
        }

        // Check oracle cache
        OracleCache memory cache = oracleCache[paymentToken];
        int256 price;
        uint256 updatedAt;

        // If cache data is fresh enough, use it
        if (cache.price > 0 && block.timestamp - cache.updatedAt < maxOracleDelay) {
            price = cache.price;
            updatedAt = cache.updatedAt;
        } else {
            // Otherwise get data directly from oracle
            (,price,,updatedAt,) = tokenConfig.priceFeed.latestRoundData();
        }

        // Check for oracle data freshness
        if (block.timestamp - updatedAt > maxOracleDelay || price <= 0) {
            return PurchasePreview(false, 0, paymentToken, 0, false, false, false, false);
        }

        uint256 vbiteAmount = _calculateVbiteAmount(paymentAmount, price, tokenConfig.decimals, rate);

        (bool silver, bool gold, bool platinum, bool bonusAvailable) = _checkNFTAvailability(vbiteAmount);

        return PurchasePreview({
            paymentTokenAccepted: true,
            paymentToken: paymentToken,
            paymentAmount: paymentAmount,
            vbiteAmount: vbiteAmount,
            willGetSilver: silver,
            willGetGold: gold,
            willGetPlatinum: platinum,
            bonusAvailable: bonusAvailable
        });
    }

    /**
     * @notice Calculates payment amount for desired VBITE amount
     * @param paymentToken Payment token address
     * @param vbiteAmount Desired amount of VBITE tokens
     * @return Preview structure with purchase details
     */
    function previewVbiteAmount(address paymentToken, uint256 vbiteAmount) public view returns (PurchasePreview memory) {
        // Checking the availability of token for payment
        TokenConfig memory tokenConfig = tokens[paymentToken];
        bool accepted = tokenConfig.accepted;

        if (!accepted || vbiteAmount == 0) {
            return PurchasePreview(false, 0, paymentToken, 0, false, false, false, false);
        }

        // Check oracle cache
        OracleCache memory cache = oracleCache[paymentToken];
        int256 price;
        uint256 updatedAt;

        // If cache data is fresh enough, use it
        if (cache.price > 0 && block.timestamp - cache.updatedAt < maxOracleDelay) {
            price = cache.price;
            updatedAt = cache.updatedAt;
        } else {
            // Otherwise get data directly from oracle
            (,price,,updatedAt,) = tokenConfig.priceFeed.latestRoundData();
        }

        // Check for oracle data freshness
        if (block.timestamp - updatedAt > maxOracleDelay || price <= 0) {
            return PurchasePreview(false, 0, paymentToken, 0, false, false, false, false);
        }

        uint256 paymentAmount = _calculatePaymentAmount(vbiteAmount, price, tokenConfig.decimals, rate);

        (bool silver, bool gold, bool platinum, bool bonusAvailable) = _checkNFTAvailability(vbiteAmount);

        return PurchasePreview({
            paymentTokenAccepted: true,
            vbiteAmount: vbiteAmount,
            paymentToken: paymentToken,
            paymentAmount: paymentAmount,
            willGetSilver: silver,
            willGetGold: gold,
            willGetPlatinum: platinum,
            bonusAvailable: bonusAvailable
        });
    }

    /**
     * @notice Updates cache for a specific token's oracle
     * @param token Token address to update
     */
    function updateOracleCache(address token) external {
        if (!tokens[token].accepted) revert TokenNotAccepted(token);
        _updateOracleCache(token);
    }

    /**
     * @notice Updates cache for all active oracles
     */
    function updateAllOracleCache() external {
        uint256 updated = 0;
        for (uint i = 0; i < activeTokens.length; i++) {
            address token = activeTokens[i];
            if (tokens[token].accepted) {
                _updateOracleCache(token);
                updated++;
            }
        }
        emit AllOracleCachesUpdated(block.timestamp, updated);
    }

    /**
     * @notice Checks if oracle cache for a token is valid
     * @param token Token address to check
     * @return Whether the cache is valid
     */
    function isOracleCacheValid(address token) public view returns (bool) {
        if (!tokens[token].accepted) return false;

        OracleCache memory cache = oracleCache[token];
        return (
            cache.price > 0 &&
            block.timestamp - cache.updatedAt < maxOracleDelay
        );
    }

    /**
     * @notice Returns time until oracle cache expiry
     * @param token Token address to check
     * @return Time in seconds until cache expires (0 if already expired)
     */
    function timeUntilCacheExpiry(address token) external view returns (uint256) {
        if (!tokens[token].accepted) return 0;

        OracleCache memory cache = oracleCache[token];
        if (cache.price <= 0) return 0;

        uint256 expiryTime = cache.updatedAt + maxOracleDelay;
        if (block.timestamp >= expiryTime) return 0;

        return expiryTime - block.timestamp;
    }

    /**
     * @notice Suspends contract operations
     */
    function pause() external onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Renews contract operations
     */
    function unpause() external onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    // ==========================================
    // Internal Functions
    // ==========================================

    /**
     * @notice Checks NFT availability based on VBITE amount
     * @param vbiteAmount Amount of VBITE tokens
     * @return isSilver Whether Silver NFT threshold is met
     * @return isGold Whether Gold NFT threshold is met
     * @return isPlatinum Whether Platinum NFT threshold is met
     * @return bonusAvailable Whether NFT bonus is available
     */
    function _checkNFTAvailability(uint256 vbiteAmount) internal view returns (bool isSilver, bool isGold, bool isPlatinum, bool bonusAvailable) {
        isSilver = vbiteAmount >= SILVER_THRESHOLD && vbiteAmount < GOLD_THRESHOLD;
        isGold = vbiteAmount >= GOLD_THRESHOLD && vbiteAmount < PLATINUM_THRESHOLD;
        isPlatinum = vbiteAmount >= PLATINUM_THRESHOLD;

        bonusAvailable = false;

        if (isPlatinum && (lifetimeNFT.totalMinted(VBITEAccessTypes.Tier.PLATINUM) < lifetimeNFT.maxSupply(VBITEAccessTypes.Tier.PLATINUM))) {
            bonusAvailable = true;
        } else if (isGold && (lifetimeNFT.totalMinted(VBITEAccessTypes.Tier.GOLD) < lifetimeNFT.maxSupply(VBITEAccessTypes.Tier.GOLD))) {
            bonusAvailable = true;
        } else if (isSilver && (lifetimeNFT.totalMinted(VBITEAccessTypes.Tier.SILVER) < lifetimeNFT.maxSupply(VBITEAccessTypes.Tier.SILVER))) {
            bonusAvailable = true;
        }

        return (isSilver, isGold, isPlatinum, bonusAvailable);
    }

    /**
     * @notice Calculates VBITE amount based on payment amount
     * @param paymentAmount Amount of payment tokens
     * @param price Oracle price
     * @param tokenDecimals Token decimals
     * @param currentRate Current exchange rate
     * @return Amount of VBITE tokens
     */
    function _calculateVbiteAmount(uint256 paymentAmount, int256 price, uint8 tokenDecimals, uint256 currentRate) internal pure returns (uint256) {
        if (price <= 0) revert OracleDataInvalid("Invalid price for calculation");
        if (currentRate == 0) revert ZeroRateProvided();
        if (tokenDecimals > 30) revert InvalidDecimals();

        uint256 priceUint = uint256(price);
        uint256 decimalsMultiplier = 10 ** tokenDecimals;

        if (paymentAmount > type(uint256).max / priceUint)
            revert CalculationOverflow("paymentAmount * price");

        uint256 usdValue = (paymentAmount * priceUint) / decimalsMultiplier;

        if (usdValue > type(uint256).max / currentRate)
            revert CalculationOverflow("usdValue * rate");

        uint256 result = (usdValue * 1e18) / currentRate ;

        return result;
    }

    /**
     * @notice Calculates payment amount for desired VBITE amount
     * @param vbiteAmount Desired amount of VBITE tokens
     * @param price Oracle price
     * @param tokenDecimals Token decimals
     * @param currentRate Current exchange rate
     * @return Amount of payment tokens required
     */
    function _calculatePaymentAmount(uint256 vbiteAmount, int256 price, uint8 tokenDecimals, uint256 currentRate) internal pure returns (uint256) {
        if (price <= 0) revert OracleDataInvalid("Invalid price for calculation");
        if (currentRate == 0) revert ZeroRateProvided();
        if (tokenDecimals > 30) revert InvalidDecimals(); // Защита от слишком больших значений

        uint256 priceUint = uint256(price);
        uint256 decimalsMultiplier = 10 ** tokenDecimals;

        if (vbiteAmount > type(uint256).max / 1e8)
            revert CalculationOverflow("vbiteAmount * 1e8");

        uint256 usdNeeded = (vbiteAmount * currentRate) / 1e18;

        if (usdNeeded > type(uint256).max / decimalsMultiplier)
            revert CalculationOverflow("usdNeeded * decimalsMultiplier");

        uint256 result = (usdNeeded * decimalsMultiplier) / priceUint;

        return result;
    }

    /**
     * @notice Calculates and transfers VBITE to user, issues NFT if eligible
     * @param payer Buyer's address
     * @param token Payment token address
     * @param amount Amount of tokens paid
     * @return vbiteAmount Amount of VBITE tokens received
     */
    function _calculateAndTransferVBITE(address payer, address token, uint256 amount) internal returns (uint256) {
        AggregatorV3Interface feed = tokens[token].priceFeed;
        OracleCache memory cache = oracleCache[token];
        int256 price;
        uint256 updatedAt;
        uint80 roundId;
        uint80 answeredInRound;

        if (cache.price > 0 && block.timestamp - cache.updatedAt < maxOracleDelay) {
            price = cache.price;
            updatedAt = cache.updatedAt;
            roundId = cache.roundId;
            answeredInRound = cache.answeredInRound; // Cache doesn't have answeredInRound, so use roundId
        } else {
            (roundId, price, , updatedAt, answeredInRound) = feed.latestRoundData();

            oracleCache[token] = OracleCache({
                price: price,
                updatedAt: updatedAt,
                roundId: roundId,
                answeredInRound: answeredInRound
            });
            emit OracleCacheUpdated(token, price, updatedAt);
        }

        if(price <= 0) revert OracleDataInvalid("Invalid oracle price");
        if(updatedAt == 0) revert OracleDataInvalid("Round not complete");
        if(answeredInRound < roundId) revert OracleDataInvalid("Stale price");
        if(block.timestamp - updatedAt >= maxOracleDelay) revert OracleDataInvalid("Oracle data too old");

        uint256 vbiteAmount = _calculateVbiteAmount(amount, price, tokens[token].decimals, rate);

        uint256 balance = vbite.balanceOf(address(this));
        if(balance < vbiteAmount) revert InsufficientVBITEBalance(vbiteAmount, balance);

        vbite.safeTransfer(payer, vbiteAmount);

        emit TokensPurchased(payer, token, amount, vbiteAmount);

        // Mint NFT if eligible
        _mintNFTIfEligible(payer, vbiteAmount);

        return vbiteAmount;
    }

    /**
     * @notice Attempts to mint an NFT to a user
     * @param user User address
     * @param tier NFT tier
     * @param threshold Tier threshold
     * @param vbiteAmount Amount of VBITE tokens
     * @dev Uses try-catch to safely handle minting failures without reverting the transaction
     */
    function _tryMintNFT(address user, VBITEAccessTypes.Tier tier, uint256 threshold, uint256 vbiteAmount) internal {
        try lifetimeNFT.hasNFTOfTierOrHigher(user, tier) returns (bool hasNFT) {
            if (vbiteAmount >= threshold && !hasNFT) {
                // Запоминаем количество NFT до минтинга
                uint256 beforeMint = lifetimeNFT.totalMinted(tier);

                lifetimeNFT.mintLifetime(user, tier);

                // Проверяем, что минтинг действительно произошел
                uint256 afterMint = lifetimeNFT.totalMinted(tier);
                if (afterMint <= beforeMint) {
                    emit NFTGrantFailure(user, abi.encodeWithSignature("NFTMintingFailed()"));
                    return;
                }

                emit NFTGranted(user, tier, vbiteAmount);
            }
        } catch (bytes memory reason) {
            emit NFTGrantFailure(user, reason);
        }

    }

    /**
     * @notice Issues NFT if user is eligible based on VBITE amount
     * @param user User address
     * @param vbiteAmount Amount of VBITE tokens
     */
    function _mintNFTIfEligible(address user, uint256 vbiteAmount) internal {
        VBITEAccessTypes.Tier tier;
        uint256 threshold;

        if (vbiteAmount >= PLATINUM_THRESHOLD) {
            tier = VBITEAccessTypes.Tier.PLATINUM;
            threshold = PLATINUM_THRESHOLD;
        } else if (vbiteAmount >= GOLD_THRESHOLD) {
            tier = VBITEAccessTypes.Tier.GOLD;
            threshold = GOLD_THRESHOLD;
        } else if (vbiteAmount >= SILVER_THRESHOLD) {
            tier = VBITEAccessTypes.Tier.SILVER;
            threshold = SILVER_THRESHOLD;
        } else {
            return; // Doesn't meet any threshold
        }

        _tryMintNFT(user, tier, threshold, vbiteAmount);
    }

    /**
     * @notice Updates oracle cache for a token
     * @param token Token address
     * @dev Also detects price anomalies and logs them via AnomalyDetected event
     */
    function _updateOracleCache(address token) internal {
        TokenConfig memory config = tokens[token];
        if (!config.accepted) return;

        (uint80 roundId, int256 price, , uint256 updatedAt, uint80 answeredInRound) = config.priceFeed.latestRoundData();

        if (oracleCache[token].price > 0) {
            int256 oldPrice = oracleCache[token].price;

            uint256 priceDiff;
            if (price > oldPrice) {
                priceDiff = (uint256(price - oldPrice) * 100) / uint256(oldPrice);
            } else {
                priceDiff = (uint256(oldPrice - price) * 100) / uint256(oldPrice);
            }

            if (priceDiff > maxPriceDeviation) {
                emit AnomalyDetected(token, oldPrice, price, priceDiff);
            }
        }

        oracleCache[token] = OracleCache({
            price: price,
            updatedAt: updatedAt,
            roundId: roundId,
            answeredInRound: answeredInRound
        });

        emit OracleCacheUpdated(token, price, updatedAt);
    }
}

