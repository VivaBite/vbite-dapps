// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/utils/ReentrancyGuard.sol";

/**
 * @title VBITEVestingVault
 * @notice Contract for the management of vesting VBITE tokens
 */
contract VBITEVestingVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct VestingSchedule {
        bool initialized;
        address beneficiary;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 initialAmount;   // Initial amount available immediately
        uint256 amountTotal;     // Total amount (including initialAmount)
        uint256 released;
        bool revocable;
        bool revoked;
    }

    IERC20 public immutable token;
    mapping(bytes32 => VestingSchedule) public vestingSchedules;
    uint256 public vestingSchedulesTotalAmount;
    uint256 public vestingSchedulesCount;
    mapping(address => bytes32[]) public holdersVestingSchedules;

    error ZeroAddressProvided();
    error InsufficientTokens();
    error InvalidVestingSchedule();
    error VestingScheduleNotFound();
    error VestingScheduleNotRevocable();
    error VestingScheduleAlreadyRevoked();
    error NoTokensToRelease();

    event VestingScheduleCreated(
        bytes32 indexed scheduleId,
        address indexed beneficiary,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        uint256 initialAmount,
        uint256 amountTotal
    );
    event VestingScheduleRevoked(bytes32 indexed scheduleId, uint256 refundedAmount);
    event TokensReleased(bytes32 indexed scheduleId, address indexed beneficiary, uint256 amount);

    /**
     * @notice Creates a vesting contract for the given token
     * @param _token Address of VBITE token
     */
    constructor(address _token) Ownable(msg.sender) {
        if(_token == address(0)) revert ZeroAddressProvided();
        token = IERC20(_token);
    }

    // ==========================================
    // Public and External Functions
    // ==========================================

    /**
     * @notice Returns the schedule ID of the session
     * @param holder Beneficiary address
     * @param index Schedule index
     * @return Schedule ID
     */
    function computeVestingScheduleIdForAddressAndIndex(address holder, uint256 index)
    public pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(holder, index));
    }

    /**
     * @notice Returns the token amount locked in this contract
     * @return Amount of locked tokens
     */
    function getWithdrawableAmount()
    public view
    returns (uint256)
    {
        return token.balanceOf(address(this)) - vestingSchedulesTotalAmount;
    }

    /**
     * @notice Returns the schedule ID for the specified beneficiary and index
     * @param holder Beneficiary address
     * @param index Schedule index
     * @return Schedule ID
     */
    function getVestingScheduleIdAtIndex(address holder, uint256 index)
    external view
    returns (bytes32)
    {
        return holdersVestingSchedules[holder][index];
    }

    /**
     * @notice Returns the number of schedules to check out for the specified beneficiary
     * @param holder Beneficiary address
     * @return Number of schedules
     */
    function getVestingSchedulesCountByHolder(address holder)
    external view
    returns (uint256)
    {
        return holdersVestingSchedules[holder].length;
    }

    /**
     * @notice Creates a new schedule for the session
     * @param _beneficiary Beneficiary address
     * @param _start Start time of the Vesting (unix time)
     * @param _cliff Cliff time (unix time)
     * @param _duration Duration in seconds
     * @param _initialAmount Initial amount available immediately
     * @param _amountTotal Total amount of the vesting (including initialAmount)
     * @param _revocable Flag of recall
     * @return scheduleId Created schedule ID
     */
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _initialAmount,
        uint256 _amountTotal,
        bool _revocable
    )
    external onlyOwner nonReentrant
    returns (bytes32 scheduleId)
    {
        if(_beneficiary == address(0)) revert ZeroAddressProvided();
        if(_amountTotal == 0) revert InvalidVestingSchedule();
        if(_initialAmount > _amountTotal) revert InvalidVestingSchedule();
        if(_duration == 0) revert InvalidVestingSchedule();
        if(_cliff < _start) revert InvalidVestingSchedule();

        uint256 currentBalance = token.balanceOf(address(this));
        if(currentBalance < vestingSchedulesTotalAmount + _amountTotal) {
            revert InsufficientTokens();
        }

        uint256 holderScheduleCount = holdersVestingSchedules[_beneficiary].length;
        scheduleId = computeVestingScheduleIdForAddressAndIndex(_beneficiary, holderScheduleCount);

        holdersVestingSchedules[_beneficiary].push(scheduleId);

        vestingSchedules[scheduleId] = VestingSchedule({
            initialized: true,
            beneficiary: _beneficiary,
            cliff: _cliff,
            start: _start,
            duration: _duration,
            initialAmount: _initialAmount,
            amountTotal: _amountTotal,
            released: 0,
            revocable: _revocable,
            revoked: false
        });

        vestingSchedulesTotalAmount += _amountTotal;
        vestingSchedulesCount++;

        emit VestingScheduleCreated(
            scheduleId,
            _beneficiary,
            _start,
            _cliff,
            _duration,
            _initialAmount,
            _amountTotal
        );

        if(_initialAmount > 0) {
            _release(scheduleId, _initialAmount);
        }

        return scheduleId;
    }

    /**
     * @notice Revokes a vesting schedule if it is revocable
     * @dev Only callable by the owner
     * @param scheduleId Schedule ID to revoke
     */
    function revoke(bytes32 scheduleId)
    external onlyOwner nonReentrant
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[scheduleId];

        if(!vestingSchedule.initialized) revert VestingScheduleNotFound();
        if(!vestingSchedule.revocable) revert VestingScheduleNotRevocable();
        if(vestingSchedule.revoked) revert VestingScheduleAlreadyRevoked();

        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        uint256 refundAmount = vestingSchedule.amountTotal - vestingSchedule.released - vestedAmount;

        vestingSchedule.revoked = true;

        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount - refundAmount;

        if(vestedAmount > 0) {
            _release(scheduleId, vestedAmount);
        }

        if(refundAmount > 0) {
            token.safeTransfer(owner(), refundAmount);
        }

        emit VestingScheduleRevoked(scheduleId, refundAmount);
    }

    /**
     * @notice Releases available tokens to the beneficiary
     * @dev Can be called by the beneficiary or the owner
     * @param scheduleId Schedule ID to release tokens from
     */
    function release(bytes32 scheduleId)
    external nonReentrant
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[scheduleId];

        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isOwner = msg.sender == owner();
        if(!isBeneficiary && !isOwner) revert VestingScheduleNotFound();

        uint256 amount = _computeReleasableAmount(vestingSchedule);
        if(amount == 0) revert NoTokensToRelease();

        _release(scheduleId, amount);
    }

    /**
     * @notice Returns the schedule of the session by ID
     * @param scheduleId Schedule ID
     * @return VestingSchedule schedule struct
     */
    function getVestingSchedule(bytes32 scheduleId)
    external view
    returns (VestingSchedule memory)
    {
        return vestingSchedules[scheduleId];
    }

    /**
     * @notice Calculates the amount that can be unlocked for the specified schedule
     * @param scheduleId Schedule ID
     * @return Amount available to unlock
     */
    function computeReleasableAmount(bytes32 scheduleId)
    external view
    returns (uint256)
    {
        VestingSchedule memory vestingSchedule = vestingSchedules[scheduleId];
        return _computeReleasableAmount(vestingSchedule);
    }

    /**
     * @notice Returns total token balance for specified holder
     * @param holder Honder address
     * @return Total token balance
     */
    function getVestingSchedulesTotalAmount(address holder)
    external view
    returns (uint256)
    {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < holdersVestingSchedules[holder].length; i++) {
            bytes32 scheduleId = holdersVestingSchedules[holder][i];
            VestingSchedule storage schedule = vestingSchedules[scheduleId];
            if (!schedule.revoked) {
                totalAmount += schedule.amountTotal - schedule.released;
            }
        }
        return totalAmount;
    }

    /**
     * @notice Allows the owner to withdraw unlocked tokens
     * @dev Only callable by the owner
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount)
    external onlyOwner nonReentrant
    {
        uint256 withdrawable = getWithdrawableAmount();
        if(amount > withdrawable) revert InsufficientTokens();
        token.safeTransfer(owner(), amount);
    }

    // ==========================================
    // Internal Functions
    // ==========================================

    /**
     * @notice Calculates the releasable amount for a vesting schedule
     * @param vestingSchedule Vesting schedule to calculate for
     * @return uint256 Amount that can be released
     */
    function _computeReleasableAmount(VestingSchedule memory vestingSchedule)
    internal view
    returns (uint256)
    {
        if(vestingSchedule.revoked || !vestingSchedule.initialized) {
            return 0;
        }

        if(block.timestamp < vestingSchedule.cliff) {
            return 0;
        }

        if(block.timestamp >= vestingSchedule.start + vestingSchedule.duration) {
            return vestingSchedule.amountTotal - vestingSchedule.released;
        }

        uint256 timeFromStart = block.timestamp - vestingSchedule.start;
        uint256 vestedAmount = vestingSchedule.initialAmount +
            (vestingSchedule.amountTotal - vestingSchedule.initialAmount) *
            timeFromStart / vestingSchedule.duration;

        return vestedAmount - vestingSchedule.released;
    }

    /**
     * @notice Releases tokens to the beneficiary
     * @param scheduleId Schedule ID
     * @param amount Amount to release
     */
    function _release(bytes32 scheduleId, uint256 amount)
    internal
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[scheduleId];

        vestingSchedule.released += amount;
        vestingSchedulesTotalAmount -= amount;

        token.safeTransfer(vestingSchedule.beneficiary, amount);

        emit TokensReleased(scheduleId, vestingSchedule.beneficiary, amount);
    }

}
