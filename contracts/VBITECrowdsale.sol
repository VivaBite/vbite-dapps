// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./VBITEAccessTypes.sol";
import "@chainlink/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/utils/Address.sol";
import "@openzeppelin/utils/Pausable.sol";
import "@openzeppelin/utils/ReentrancyGuard.sol";
import "@openzeppelin/governance/TimelockController.sol";

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
