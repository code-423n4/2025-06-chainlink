// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IBUILDFactory} from "./interfaces/IBUILDFactory.sol";
import {ITypeAndVersion} from "chainlink/contracts/src/v0.8/shared/interfaces/ITypeAndVersion.sol";

import {IBUILDClaim} from "./interfaces/IBUILDClaim.sol";
import {BUILDClaim} from "./BUILDClaim.sol";
import {ManagedAccessControl} from "./ManagedAccessControl.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {FixedPointMathLib} from "@solmate/FixedPointMathLib.sol";
import {IDelegateRegistry} from "@delegatexyz/delegate-registry/v2.0/src/IDelegateRegistry.sol";

contract BUILDFactory is IBUILDFactory, ITypeAndVersion, ManagedAccessControl {
  using EnumerableSet for EnumerableSet.AddressSet;
  using FixedPointMathLib for uint256;

  /// @inheritdoc ITypeAndVersion
  string public constant override typeAndVersion = "BUILDFactory 1.0.0";

  /// @notice Parameters required to instantiate the BUILDFactory contract
  struct ConstructorParams {
    address admin; // ───────────────────╮ The initial factory admin address
    uint40 maxUnlockDuration; //         │ The initial max unlock duration
    uint40 maxUnlockDelay; // ───────────╯ The initial max unlock delay
    IDelegateRegistry delegateRegistry; // The initial delegate registry contract
  }

  /// @notice The maximum unlock duration and delay values allowed
  UnlockMaxConfigs private s_unlockMaxConfigs;

  /// @notice The set of project addresses
  EnumerableSet.AddressSet private s_projectsList;

  /// @notice The delegate registry contract
  IDelegateRegistry private s_delegateRegistry;

  /// @notice The project configs
  mapping(address token => ProjectConfig config) private s_projects;

  /// @notice The season unlock start times for all projects
  mapping(uint256 seasonId => uint256 unlockStartsAt) private s_seasonUnlockStartTimes;

  /// @notice The project season configs
  mapping(address token => mapping(uint256 seasonId => ProjectSeasonConfig config)) private
    s_projectSeasonConfigs;

  /// @notice The amount of tokens that can be refunded to a project for each season
  /// @dev This is the amount of tokens that corresponds to the credits of the users who have not
  /// claimed anything yet from the season, and may be refunded for their credits in the future.
  /// The project can reclaim these tokens if the users don't claim them until the refund phase
  /// starts.
  mapping(address token => mapping(uint256 seasonId => uint256 amount)) private s_refundableAmounts;

  /// @notice Mapping of token amounts per project
  mapping(address token => TokenAmounts) private s_tokenAmounts;

  /// @notice The parameters for a scheduled withdrawal, if any
  mapping(address token => Withdrawal) private s_withdrawals;

  /// @notice Pause state for claim contracts by project
  mapping(address token => bool paused) private s_claimPaused;

  /// @notice The basis points denominator for percentages
  uint256 private constant PERCENTAGE_BASIS_POINTS_DENOMINATOR = 10_000;

  // ================================================================
  // |                       Initialization                         |
  // ================================================================

  /// @dev We set the adminRoleTransferDelay to 0 (no delay)
  /// @dev In AccessControlDefaultAdminRules, we check that params.admin is not a zero address and
  /// set it as the initial defaultAdmin, with the DEFAULT_ADMIN_ROLE role.
  constructor(
    ConstructorParams memory params
  ) ManagedAccessControl(0, params.admin) {
    _setUnlockConfigMaxValues(
      IBUILDFactory.UnlockMaxConfigs({
        maxUnlockDelay: params.maxUnlockDelay,
        maxUnlockDuration: params.maxUnlockDuration
      })
    );
    _setDelegateRegistry(params.delegateRegistry);
  }

  // ================================================================
  // |                     Project Allowlisting                     |
  // ================================================================

  /// @inheritdoc IBUILDFactory
  function addProjects(
    AddProjectParams[] calldata projects
  ) external override whenOpen onlyRole(DEFAULT_ADMIN_ROLE) {
    // Cache array length outside loop
    uint256 projectsLength = projects.length;
    for (uint256 i = 0; i < projectsLength; ++i) {
      AddProjectParams memory params = projects[i];
      if (
        params.admin == address(0) || params.token == address(0)
          || IERC20Metadata(params.token).decimals() == 0
      ) {
        revert InvalidAddProjectParams();
      }
      ProjectConfig storage project = s_projects[params.token];
      project.admin = params.admin;
      s_projectsList.add(params.token);

      emit ProjectAddedOrAdminChanged(params.token, project.admin);
    }
  }

  /// @inheritdoc IBUILDFactory
  function removeProjects(
    address[] calldata tokens
  ) external override whenOpen onlyRole(DEFAULT_ADMIN_ROLE) {
    EnumerableSet.AddressSet storage projectsList = s_projectsList;
    // Cache array length outside loop
    uint256 tokensLength = tokens.length;
    for (uint256 i = 0; i < tokensLength; ++i) {
      address token = tokens[i];
      if (!projectsList.remove(token)) {
        revert ProjectDoesNotExist(token);
      }
      delete s_projects[token];

      emit ProjectRemoved(token);
    }
  }

  /// @inheritdoc IBUILDFactory
  function getProjects() external view override returns (address[] memory) {
    return s_projectsList.values();
  }

  /// @inheritdoc IBUILDFactory
  function getProjectConfig(
    address token
  ) external view override returns (ProjectConfig memory) {
    return s_projects[token];
  }

  /// @inheritdoc IBUILDFactory
  function deployClaim(
    address token
  ) external override whenOpen whenNotPaused returns (IBUILDClaim) {
    _ensureProjectExists(token);
    ProjectConfig storage project = s_projects[token];
    if (msg.sender != project.admin) revert Unauthorized();
    if (address(project.claim) != address(0)) {
      revert ClaimAlreadyExists(token, address(project.claim));
    }

    BUILDClaim claim = new BUILDClaim(token);
    project.claim = claim;
    emit ClaimDeployed(token, address(claim));
    return IBUILDClaim(claim);
  }

  /// @notice Util to ensure only the claims contract can call a function
  /// @param token The project token address
  function _requireRegisteredClaim(
    address token
  ) internal view {
    if (address(s_projects[token].claim) != msg.sender) {
      revert Unauthorized();
    }
  }

  // ================================================================
  // |                     Season Configuration                     |
  // ================================================================

  /// @inheritdoc IBUILDFactory
  function setUnlockConfigMaxValues(
    UnlockMaxConfigs calldata config
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) whenOpen {
    _setUnlockConfigMaxValues(config);
  }

  /// @notice Util function to set the maximum unlock duration and delay
  /// @param config The new maximum unlock duration and unlock delay
  function _setUnlockConfigMaxValues(
    UnlockMaxConfigs memory config
  ) private {
    if (config.maxUnlockDuration == 0) {
      revert InvalidZeroMaxUnlockDuration();
    }

    if (config.maxUnlockDelay == 0) {
      revert InvalidZeroMaxUnlockDelay();
    }

    UnlockMaxConfigs storage currentMax = s_unlockMaxConfigs;
    if (currentMax.maxUnlockDuration != config.maxUnlockDuration) {
      currentMax.maxUnlockDuration = config.maxUnlockDuration;
      emit MaxUnlockDurationUpdated(config.maxUnlockDuration);
    }
    if (currentMax.maxUnlockDelay != config.maxUnlockDelay) {
      currentMax.maxUnlockDelay = config.maxUnlockDelay;
      emit MaxUnlockDelayUpdated(config.maxUnlockDelay);
    }
  }

  /// @inheritdoc IBUILDFactory
  function getUnlockConfigMaxValues() external view override returns (UnlockMaxConfigs memory) {
    return s_unlockMaxConfigs;
  }

  /// @inheritdoc IBUILDFactory
  function setSeasonUnlockStartTime(
    uint256 seasonId,
    uint256 unlockStartsAt
  ) external override whenOpen onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 currentUnlockStartTime = s_seasonUnlockStartTimes[seasonId];
    // A start time of 0 means it has not been set yet
    bool hasUnlockStarted = currentUnlockStartTime != 0 && currentUnlockStartTime <= block.timestamp;
    if (hasUnlockStarted || unlockStartsAt <= block.timestamp) {
      revert InvalidUnlockStartsAt(seasonId, unlockStartsAt);
    }
    s_seasonUnlockStartTimes[seasonId] = unlockStartsAt;
    emit SeasonUnlockStartTimeUpdated(seasonId, unlockStartsAt);
  }

  /// @inheritdoc IBUILDFactory
  function setProjectSeasonConfig(
    SetProjectSeasonParams[] calldata params
  ) external override whenOpen onlyRole(DEFAULT_ADMIN_ROLE) {
    for (uint256 i = 0; i < params.length; ++i) {
      _setProjectSeasonConfig(params[i]);
    }
  }

  /// @notice Internal function to set the project season config
  /// @dev This function is called by the setProjectSeasonConfig function
  /// @param params The parameters for the project season config
  function _setProjectSeasonConfig(
    SetProjectSeasonParams calldata params
  ) internal {
    _requireClaimNotPaused(params.token);
    _ensureProjectExists(params.token);
    uint256 unlockStartsAt = s_seasonUnlockStartTimes[params.seasonId];
    if (unlockStartsAt == 0) {
      revert SeasonDoesNotExist(params.seasonId);
    }
    if (unlockStartsAt <= block.timestamp) {
      revert SeasonAlreadyStarted(params.seasonId);
    }
    ProjectSeasonConfig storage currentConfig =
      s_projectSeasonConfigs[params.token][params.seasonId];
    if (currentConfig.isRefunding) {
      revert ProjectSeasonIsRefunding(params.token, params.seasonId);
    }
    ProjectSeasonConfig memory config = params.config;
    UnlockMaxConfigs memory unlockMaxConfigs = s_unlockMaxConfigs;
    if (config.isRefunding) {
      // Ignore the isRefunding flag, starting refund should be done with the startRefund function
      config.isRefunding = false;
    }
    if (config.unlockDuration == 0 || config.unlockDuration > unlockMaxConfigs.maxUnlockDuration) {
      revert InvalidUnlockDuration(params.seasonId, config.unlockDuration);
    }
    if (config.unlockDelay > unlockMaxConfigs.maxUnlockDelay) {
      revert InvalidUnlockDelay(params.seasonId, config.unlockDelay);
    }
    // prevent overflow for UserState.claimed value
    if (config.tokenAmount == 0 || config.tokenAmount > type(uint248).max) {
      revert InvalidTokenAmount(params.seasonId);
    }
    if (
      config.baseTokenClaimBps > PERCENTAGE_BASIS_POINTS_DENOMINATOR
        || (
          config.baseTokenClaimBps == PERCENTAGE_BASIS_POINTS_DENOMINATOR && config.unlockDuration > 1
        )
    ) {
      revert InvalidBaseTokenClaimBps(
        params.seasonId, config.baseTokenClaimBps, config.unlockDuration
      );
    }

    if (
      config.earlyVestRatioMaxBps > PERCENTAGE_BASIS_POINTS_DENOMINATOR
        || config.earlyVestRatioMinBps > config.earlyVestRatioMaxBps
    ) {
      revert InvalidEarlyVestRatios(config.earlyVestRatioMinBps, config.earlyVestRatioMaxBps);
    }

    _setSeasonTokenAmount(
      params.token, params.seasonId, config.tokenAmount, currentConfig.tokenAmount
    );
    currentConfig.tokenAmount = config.tokenAmount;
    currentConfig.baseTokenClaimBps = config.baseTokenClaimBps;
    currentConfig.unlockDelay = config.unlockDelay;
    currentConfig.unlockDuration = config.unlockDuration;
    currentConfig.merkleRoot = config.merkleRoot;
    currentConfig.earlyVestRatioMinBps = config.earlyVestRatioMinBps;
    currentConfig.earlyVestRatioMaxBps = config.earlyVestRatioMaxBps;

    emit ProjectSeasonConfigUpdated(params.token, params.seasonId, currentConfig);
  }

  /// @notice Internal function to set the season allocated and refundable token amounts
  /// @dev The new amount must be less than or equal to the max available amount, based on the total
  /// deposit, withdrawal, refunded and season-allocated amounts.
  /// @param token The project's token address
  /// @param seasonId The season id
  /// @param amount The new token amount
  /// @param currentAmount The current token amount
  function _setSeasonTokenAmount(
    address token,
    uint256 seasonId,
    uint256 amount,
    uint256 currentAmount
  ) internal {
    TokenAmounts storage tokenAmounts = s_tokenAmounts[token];
    uint256 totalAllocatedAmountBefore = tokenAmounts.totalAllocatedToAllSeasons;
    uint256 maxAvailable = _calcMaxAvailableForWithdrawalOrNewSeason(tokenAmounts);
    // If the season is being updated, the current amount allocated to the same season should be
    // added to the max available amount.
    // If there is a scheduled withdrawal, the amount should be subtracted from the max available
    // amount.
    // The validation for amount > 0 is done in the BUILDFactory.setProjectSeasonConfig that
    // calls this function.
    maxAvailable = maxAvailable + currentAmount - s_withdrawals[token].amount;
    if (amount > maxAvailable) {
      revert InsufficientFunds(token, seasonId, amount, maxAvailable);
    }
    bool isUpdating = currentAmount != 0;
    if (isUpdating) {
      tokenAmounts.totalAllocatedToAllSeasons -= currentAmount;
    }
    tokenAmounts.totalAllocatedToAllSeasons += amount;
    s_refundableAmounts[token][seasonId] = amount;
    emit ProjectTotalAllocatedUpdated(
      token, totalAllocatedAmountBefore, tokenAmounts.totalAllocatedToAllSeasons
    );
  }

  /// @inheritdoc IBUILDFactory
  function getSeasonUnlockStartTime(
    uint256 seasonId
  ) external view override returns (uint256) {
    return s_seasonUnlockStartTimes[seasonId];
  }

  /// @inheritdoc IBUILDFactory
  function getProjectSeasonConfig(
    address token,
    uint256 seasonId
  ) external view override returns (ProjectSeasonConfig memory, uint256 seasonUnlockStartTime) {
    return (s_projectSeasonConfigs[token][seasonId], s_seasonUnlockStartTimes[seasonId]);
  }

  // ================================================================
  // |                       Token Accounting                       |
  // ================================================================

  /// @inheritdoc IBUILDFactory
  function addTotalDeposited(address token, uint256 amount) external override returns (uint256) {
    _requireRegisteredClaim(token);
    if (amount == 0) {
      revert InvalidAmount();
    }
    TokenAmounts storage tokenAmounts = s_tokenAmounts[token];
    uint256 newTotalDeposited = tokenAmounts.totalDeposited + amount;
    tokenAmounts.totalDeposited = newTotalDeposited;
    emit ProjectTotalDepositedIncreased(token, msg.sender, amount, newTotalDeposited);
    return newTotalDeposited;
  }

  /// @inheritdoc IBUILDFactory
  function reduceRefundableAmount(
    address token,
    uint256 seasonId,
    uint256 amount
  ) external override {
    _requireRegisteredClaim(token);
    uint256 currentRefundableAmount = s_refundableAmounts[token][seasonId];
    // amount cannot be greater than the refundable amount for the project
    if (amount > currentRefundableAmount) {
      revert InvalidAmount();
    }
    s_refundableAmounts[token][seasonId] -= amount;
    emit ProjectSeasonRefundableAmountReduced(
      token, seasonId, amount, currentRefundableAmount - amount
    );
  }

  /// @inheritdoc IBUILDFactory
  function getTokenAmounts(
    address token
  ) external view override returns (TokenAmounts memory) {
    return s_tokenAmounts[token];
  }

  /// @inheritdoc IBUILDFactory
  function startRefund(
    address token,
    uint256 seasonId
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
    ProjectSeasonConfig storage config = s_projectSeasonConfigs[token][seasonId];
    if (config.tokenAmount == 0) {
      revert ProjectSeasonDoesNotExist(seasonId, token);
    }
    if (config.isRefunding) {
      revert ProjectSeasonIsRefunding(token, seasonId);
    }
    config.isRefunding = true;

    uint256 refundEligible = s_refundableAmounts[token][seasonId];
    uint256 totalLoyaltyRefundEligible =
      _getTotalLoyaltyRefundEligible(token, seasonId, config.tokenAmount, refundEligible);
    s_tokenAmounts[token].totalRefunded += refundEligible + totalLoyaltyRefundEligible;
    emit ProjectSeasonRefundStarted(token, seasonId);
  }

  /// @notice Returns the loyalty token amount for users who are eligible for refunds
  /// @param tokenAmount The total token amount allocated for the season
  /// @param seasonId The season id
  /// @param tokenAmount The project token amount for the season
  /// @param refundEligible The amount of tokens that can be refunded to the project for the season
  /// @return The loyalty token amount for users who are eligible for refunds
  function _getTotalLoyaltyRefundEligible(
    address token,
    uint256 seasonId,
    uint256 tokenAmount,
    uint256 refundEligible
  ) internal view returns (uint256) {
    IBUILDClaim.GlobalState memory globalState = s_projects[token].claim.getGlobalState(seasonId);
    if (globalState.totalLoyalty == 0) {
      return 0;
    }
    // By definition tokenAmount is always greater than or equal to totalLoyaltyIneligible
    uint256 totalLoyaltyEligible = tokenAmount - globalState.totalLoyaltyIneligible;

    // no loyalty eligible, entire loyalty pool is refundable
    if (totalLoyaltyEligible == 0) {
      return globalState.totalLoyalty;
    }
    return globalState.totalLoyalty.mulWadDown(refundEligible).divWadDown(totalLoyaltyEligible);
  }

  /// @inheritdoc IBUILDFactory
  function isRefunding(address token, uint256 seasonId) external view override returns (bool) {
    return s_projectSeasonConfigs[token][seasonId].isRefunding;
  }

  /// @inheritdoc IBUILDFactory
  function getRefundableAmount(
    address token,
    uint256 seasonId
  ) external view override returns (uint256) {
    ProjectSeasonConfig memory config = s_projectSeasonConfigs[token][seasonId];
    uint256 refundEligible = s_refundableAmounts[token][seasonId];
    uint256 totalLoyaltyRefundEligible =
      _getTotalLoyaltyRefundEligible(token, seasonId, config.tokenAmount, refundEligible);
    return s_refundableAmounts[token][seasonId] + totalLoyaltyRefundEligible;
  }

  /// @inheritdoc IBUILDFactory
  function calcMaxAvailableAmount(
    address token
  ) external view override returns (uint256) {
    return _calcMaxAvailableForWithdrawalOrNewSeason(s_tokenAmounts[token]);
  }

  /// @notice Calculates the maximum available amount that can be used for allocation to a new
  /// season or withdrawn
  /// @param tokenAmounts The project's token amounts
  function _calcMaxAvailableForWithdrawalOrNewSeason(
    TokenAmounts memory tokenAmounts
  ) private pure returns (uint256) {
    return tokenAmounts.totalDeposited + tokenAmounts.totalRefunded - tokenAmounts.totalWithdrawn
      - tokenAmounts.totalAllocatedToAllSeasons;
  }

  // ================================================================
  // |                      Token Withdrawals                       |
  // ================================================================

  /// @inheritdoc IBUILDFactory
  function scheduleWithdraw(
    address token,
    address recipient,
    uint256 amount
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    if (recipient == address(0)) {
      revert InvalidWithdrawalRecipient(recipient);
    }
    _validateNewWithdrawal(token, amount);
    s_withdrawals[token] = Withdrawal({recipient: recipient, amount: amount});
    emit WithdrawalScheduled(token, recipient, amount);
  }

  /// @inheritdoc IBUILDFactory
  function cancelWithdraw(
    address token
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    Withdrawal memory withdrawal = s_withdrawals[token];
    if (withdrawal.recipient == address(0) || withdrawal.amount == 0) {
      revert WithdrawalDoesNotExist(token);
    }
    delete s_withdrawals[token];
    emit WithdrawalCancelled(token, withdrawal.recipient, withdrawal.amount);
  }

  /// @inheritdoc IBUILDFactory
  function executeWithdraw(
    address token
  ) external override returns (IBUILDFactory.Withdrawal memory, uint256) {
    _requireRegisteredClaim(token);
    BUILDFactory.Withdrawal memory withdrawal = s_withdrawals[token];
    if (withdrawal.recipient == address(0) || withdrawal.amount == 0) {
      revert WithdrawalDoesNotExist(token);
    }
    _validateNewWithdrawal(token, withdrawal.amount);
    s_tokenAmounts[token].totalWithdrawn += withdrawal.amount;
    delete s_withdrawals[token];

    emit WithdrawalExecuted(
      token, withdrawal.recipient, withdrawal.amount, s_tokenAmounts[token].totalWithdrawn
    );
    return (withdrawal, s_tokenAmounts[token].totalWithdrawn);
  }

  /// @inheritdoc IBUILDFactory
  function getScheduledWithdrawal(
    address token
  ) external view override returns (Withdrawal memory) {
    return s_withdrawals[token];
  }

  /// @notice Checks if the withdrawal amount is valid
  /// @dev Throws if the amount is zero or the project does not have enough tokens to withdraw the
  /// amount
  /// @param token The project token address
  /// @param amount The withdrawal amount
  function _validateNewWithdrawal(address token, uint256 amount) private view {
    // Use != 0 instead of > 0 for unsigned integer comparison
    if (isClaimContractPaused(token) && amount != 0) {
      // If the claim contract is emergency paused, we bypass the available amount validation and
      // allow the project to withdraw the remaining tokens.
      return;
    }
    uint256 maxAvailable = _calcMaxAvailableForWithdrawalOrNewSeason(s_tokenAmounts[token]);
    if (amount == 0 || amount > maxAvailable) {
      revert InvalidWithdrawalAmount(amount, maxAvailable);
    }
  }

  // ================================================================
  // |                      Pausing Projects                        |
  // ================================================================

  /// @inheritdoc IBUILDFactory
  function pauseClaimContract(
    address token
  ) external override onlyRole(PAUSER_ROLE) {
    _requireClaimNotPaused(token);
    _ensureProjectExists(token);
    s_claimPaused[token] = true;
    emit ClaimPaused(token);
  }

  /// @inheritdoc IBUILDFactory
  function unpauseClaimContract(
    address token
  ) external override onlyRole(PAUSER_ROLE) {
    if (!isClaimContractPaused(token)) {
      revert ExpectedPause();
    }
    _ensureProjectExists(token);
    s_claimPaused[token] = false;
    emit ClaimUnpaused(token);
  }

  /// @inheritdoc IBUILDFactory
  function isClaimContractPaused(
    address token
  ) public view override returns (bool) {
    return paused() || s_claimPaused[token];
  }

  /// @notice throws if the claims contract is paused.
  /// @param token address of the project token
  function _requireClaimNotPaused(
    address token
  ) internal view virtual {
    if (isClaimContractPaused(token)) {
      revert EnforcedPause();
    }
  }

  /// @notice throws if the project does not exist.
  /// @param token address of the project token
  function _ensureProjectExists(
    address token
  ) internal view {
    if (!s_projectsList.contains(token)) revert ProjectDoesNotExist(token);
  }

  /// ================================================================
  /// |                     Delegate Registry                        |
  /// ================================================================

  function getDelegateRegistry() external view returns (IDelegateRegistry) {
    return s_delegateRegistry;
  }

  function setDelegateRegistry(
    IDelegateRegistry delegateRegistry
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setDelegateRegistry(delegateRegistry);
  }

  function _setDelegateRegistry(
    IDelegateRegistry delegateRegistry
  ) internal {
    if (address(delegateRegistry) == address(0)) {
      revert InvalidZeroAddress();
    }
    if (address(delegateRegistry) == address(s_delegateRegistry)) {
      return;
    }
    s_delegateRegistry = delegateRegistry;
    emit DelegateRegistryUpdated(address(delegateRegistry));
  }
}
