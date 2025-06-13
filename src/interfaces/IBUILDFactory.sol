// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {BUILDClaim} from "../BUILDClaim.sol";
import {IBUILDClaim} from "./IBUILDClaim.sol";

interface IBUILDFactory {
  /// @notice This event is emitted when a new project is added or its admin changed
  /// @param token The project token
  /// @param admin The new project admin
  event ProjectAddedOrAdminChanged(address indexed token, address admin);

  /// @notice This event is emitted when an existing project is removed
  /// @param token The project token
  event ProjectRemoved(address indexed token);

  /// @notice This event is emitted when a season config is updated
  /// @param seasonId The season id
  /// @param unlockStartsAt The season's unlock start time
  event SeasonUnlockStartTimeUpdated(uint256 indexed seasonId, uint256 unlockStartsAt);

  /// @notice This event is emitted when the maxUnlockDuration is updated
  /// @param maxUnlockDuration The new maximum unlock duration
  event MaxUnlockDurationUpdated(uint40 maxUnlockDuration);

  /// @notice This event is emitted when the maxUnlockDelay is updated
  /// @param maxUnlockDelay The new maximum unlock delay
  event MaxUnlockDelayUpdated(uint40 maxUnlockDelay);

  /// @notice this event is emitted when a project's season config is changed
  /// @param token The project token
  /// @param seasonId The season id
  /// @param config The new project season config
  event ProjectSeasonConfigUpdated(
    address indexed token, uint256 indexed seasonId, ProjectSeasonConfig config
  );

  /// @notice this event is emitted when the total deposited amount of a project is increased
  /// @param token The project token
  /// @param sender The sender address
  /// @param amount The deposit amount
  /// @param totalDeposited The cumulative deposited amount of the project after the update
  event ProjectTotalDepositedIncreased(
    address indexed token, address indexed sender, uint256 amount, uint256 totalDeposited
  );

  /// @notice this event is emitted when the total allocated amount of a token is updated
  /// @param token The project token
  /// @param totalAllocatedToAllSeasonsPrev The cumulative amount allocated before the update
  /// @param totalAllocatedToAllSeasons The cumulative amount allocated after the update
  event ProjectTotalAllocatedUpdated(
    address indexed token,
    uint256 totalAllocatedToAllSeasonsPrev,
    uint256 totalAllocatedToAllSeasons
  );

  /// @notice this event is emitted when a token withdrawal is scheduled
  /// @param token The project token
  /// @param recipient The recipient address
  /// @param amount The withdrawal amount
  event WithdrawalScheduled(address indexed token, address indexed recipient, uint256 amount);

  /// @notice this event is emitted when a token withdrawal is cancelled
  /// @param token The project token
  /// @param recipient The previous recipient address
  /// @param amount The previous withdrawal amount
  event WithdrawalCancelled(address indexed token, address indexed recipient, uint256 amount);

  /// @notice this event is emitted when a token withdrawal is executed
  /// @param token The project token
  /// @param recipient The recipient address
  /// @param amount The withdrawal amount
  /// @param totalWithdrawn The cumulative amount withdrawn on the token after the update
  event WithdrawalExecuted(
    address indexed token, address indexed recipient, uint256 amount, uint256 totalWithdrawn
  );

  /// @notice This event is emitted when a new claim contract is deployed for a project
  /// @param token The project token
  /// @param claim The project claim contract
  event ClaimDeployed(address indexed token, address indexed claim);

  /// @notice This event is emitted when a claim contract is paused
  /// @param token The project token
  event ClaimPaused(address indexed token);

  /// @notice This event is emitted when a claim contract is unpaused
  /// @param token The project token
  event ClaimUnpaused(address indexed token);

  /// @notice This event is emitted when refunding has started for season and token
  /// @param token The project token
  /// @param seasonId the season id
  event ProjectSeasonRefundStarted(address indexed token, uint256 indexed seasonId);

  /// @notice This event is emitted when the refundable amount is reduced for a project season
  /// @param token The project token
  /// @param seasonId the season id
  /// @param amount the amount to reduce the project's refundable amount by
  /// @param refundableAmount the refundable amount after the update
  event ProjectSeasonRefundableAmountReduced(
    address indexed token, uint256 indexed seasonId, uint256 amount, uint256 refundableAmount
  );

  /// @notice this event is emitted when the delegate registry is updated
  /// @param delegateRegistry The address of the updated delegate registry
  event DelegateRegistryUpdated(address indexed delegateRegistry);

  /// @notice this error is thrown when the project doesn't have enough tokens to allocate for a
  /// season
  /// @param token the address of the project
  /// @param seasonId The season id
  /// @param amount The requested amount
  /// @param maxAvailable The maximum available amount
  error InsufficientFunds(address token, uint256 seasonId, uint256 amount, uint256 maxAvailable);

  /// @notice This error is thrown when attempting to add projects with invalid parameters
  error InvalidAddProjectParams();

  /// @notice This error is thrown when attempting to fetch a nonexistent project
  error ProjectDoesNotExist(address token);

  /// @notice This error is thrown when attempting to fetch a nonexistent season
  error SeasonDoesNotExist(uint256 seasonId);

  /// @notice This error is thrown when deploy a claim contract for a token when one is already
  /// deployed
  error ClaimAlreadyExists(address token, address claim);

  /// @notice This error is thrown when attempting to set a project season config for a season after
  /// its unlock start time
  /// @param seasonId The season id
  error SeasonAlreadyStarted(uint256 seasonId);

  /// @notice this error is thrown when the project season that hasn't been configured
  /// @param seasonId The season id
  error ProjectSeasonDoesNotExist(uint256 seasonId, address token);

  /// @notice This error is thrown when attempting to set a project season config or start the
  /// refund phase for a season that is refunding
  /// @param token The project token
  /// @param seasonId The season id
  error ProjectSeasonIsRefunding(address token, uint256 seasonId);

  /// @notice This error is thrown when attempting to set a season start date in the past.
  error InvalidUnlockStartsAt(uint256 seasonId, uint256 unlockStartsAt);

  /// @notice this error is thrown when a zero or a value greater than the maxUnlockDuration is
  /// provided as the project season's unlock duration
  /// @param seasonId The season id
  /// @param unlockDuration The unlock duration
  error InvalidUnlockDuration(uint256 seasonId, uint40 unlockDuration);

  /// @notice this error is thrown when a zero or a value greater than the maxUnlockDelay is
  /// provided as the project season's unlock delay
  /// @param seasonId The season id
  /// @param unlockDelay The unlock delay
  error InvalidUnlockDelay(uint256 seasonId, uint40 unlockDelay);

  /// @notice this error is thrown when a zero token amount for a season is provided
  /// @param seasonId The season id
  error InvalidTokenAmount(uint256 seasonId);

  /// @notice This error is thrown whenever a zero-address is supplied when
  /// a non-zero address is required
  error InvalidZeroAddress();

  /// @notice This error is thrown whenever an unauthorized sender calls a protected function
  error Unauthorized();

  /// @notice This error is thrown when a zero unlock duration is provided
  error InvalidZeroMaxUnlockDuration();

  /// @notice This error is thrown when a zero unlock delay is provided
  error InvalidZeroMaxUnlockDelay();

  /// @notice This error is thrown when an invalid amount that does not satisfy the system
  /// requirements is provided
  error InvalidAmount();

  /// @notice this error is thrown when a withdrawal is scheduled with a zero address as the
  /// recipient
  /// @param recipient The withdrawal recipient address
  error InvalidWithdrawalRecipient(address recipient);

  /// @notice this error is thrown when a withdrawal is scheduled with an invalid amount
  /// @param amount The withdrawal amount
  /// @param maxAvailable The maximum amount available to withdraw
  error InvalidWithdrawalAmount(uint256 amount, uint256 maxAvailable);

  /// @notice this error is thrown when attempting to cancel or execute a nonexistent withdrawal
  /// @param token The token address
  error WithdrawalDoesNotExist(address token);

  /// @notice this error is thrown when an base token claim percentage value of more than 100% is
  /// provided or when the base token claim percentage is 100% and the unlock duration is
  /// greater than 1
  /// @param seasonId The season id
  /// @param baseTokenClaimBps The base token claim percentage
  /// @param unlockDuration The unlock duration
  error InvalidBaseTokenClaimBps(uint256 seasonId, uint16 baseTokenClaimBps, uint40 unlockDuration);

  /// @notice this error is thrown when the min ratio > max ratio
  /// @param earlyVestRatioMinBps The minimum early vest ratio
  /// @param earlyVestRatioMaxBps The maximum early vest ratio
  error InvalidEarlyVestRatios(uint256 earlyVestRatioMinBps, uint256 earlyVestRatioMaxBps);

  /// @notice This struct defines the params required by the addProjects function
  struct AddProjectParams {
    address token; // The project token address
    address admin; // The project admin address
  }

  /// @notice This struct defines the configs for each project
  struct ProjectConfig {
    address admin; // The project admin address
    BUILDClaim claim; // The project claim contract
  }

  /// @notice This struct defines the configs for a single project's season
  struct ProjectSeasonConfig {
    uint256 tokenAmount; // The amount of tokens available for the project on the season
    bytes32 merkleRoot; // The root for the allowlist merkle tree
    uint40 unlockDelay; // ───────────╮ The delay after the unlock starts
      //                              │ before the tokens are claimable
    uint40 unlockDuration; //         │ The duration of the unlock period
    uint40 earlyVestRatioMinBps; //   │ The minimum early vest ratio in bps
    uint40 earlyVestRatioMaxBps; //   │ The maximum early vest ratio in bps
    uint16 baseTokenClaimBps; //      │ The base token amount that can be claimed
      //                              │ instantly in basis points. This value can be set between
      //                              │ 0 (0%) and 10000 (100%), inclusive.
    bool isRefunding; // ─────────────╯ Whether the project
      // started refunding credits for the season
  }

  /// @notice This struct defines the parameters for setting a project season config
  struct SetProjectSeasonParams {
    uint256 seasonId; // The season id
    address token; // The project token address
    ProjectSeasonConfig config; // The project season config
  }

  /// @notice The token amounts status for the project
  struct TokenAmounts {
    uint256 totalDeposited; // The total amount of tokens deposited by the project
    uint256 totalWithdrawn; // The total amount of tokens withdrawn by the project
    uint256 totalAllocatedToAllSeasons; // The total amount of tokens allocated to all seasons
    uint256 totalRefunded; // The total amount of tokens that can be reclaimed by the project
      // (corresponding to the credits amount that users have been refunded for)
  }

  /// @notice This struct defines the parameters for a scheduled withdrawal
  struct Withdrawal {
    address recipient; // The scheduled withdrawal address
    uint256 amount; // The scheduled withdrawal amount
  }

  struct UnlockMaxConfigs {
    uint40 maxUnlockDuration; // ──╮ The upper bound for the unlock duration
    uint40 maxUnlockDelay; // ─────╯ The upper bound for the unlock delay
  }

  /// @notice Allowlists one or more projects and sets the project admin
  /// Can also be used to update the project admin’s address
  /// @dev Only callable by the default admin
  /// @param projects the project's token and admin address
  function addProjects(
    AddProjectParams[] calldata projects
  ) external;

  /// @notice Removes one or more projects from the allowlist and revokes the PROJECT_ROLE from the
  /// projects’ admins
  /// @dev Only callable by the default admin
  /// @param tokens a list of project token addresses
  function removeProjects(
    address[] calldata tokens
  ) external;

  /// @notice Deploys a new claim contract for a project
  /// The project must be allowlisted first
  /// Only callable by the project admin
  /// @param token The project token address
  function deployClaim(
    address token
  ) external returns (IBUILDClaim);

  /// @notice Sets the upper bounds for the unlock duration and the delay
  /// @dev Only callable by the default admin
  /// @dev Only callable when the contract is open
  /// @param config The new maximum unlock duration and unlock delay
  function setUnlockConfigMaxValues(
    UnlockMaxConfigs calldata config
  ) external;

  /// @notice Sets the unlock starting time of the new season
  /// @dev Cannot set a season's unlock start time after the season has started
  /// @dev Only callable by the default admin
  /// @param seasonId The season id
  /// @param unlockStartsAt The season's unlock start time
  function setSeasonUnlockStartTime(uint256 seasonId, uint256 unlockStartsAt) external;

  /// @notice Updates the configs for a project's single season
  /// @param params The season config parameters
  /// Only callable by the admin of the BUILDFactory
  function setProjectSeasonConfig(
    SetProjectSeasonParams[] calldata params
  ) external;

  /// @notice Pauses claim contract for a specific project
  /// @dev Only callable by the pauser role
  /// @dev The emergencyPause is used to pause all claim contracts as well as the factory contract
  /// @param token The project token
  function pauseClaimContract(
    address token
  ) external;

  /// @notice Unpauses claim contract for a specific project
  /// @dev Only callable by the pauser role
  /// @dev The emergencyUnpause is used to unpause all claim contracts as well as the factory
  /// contract
  /// @dev A claim contract cannot be unpaused if the factory is paused
  /// @param token The project token
  function unpauseClaimContract(
    address token
  ) external;

  /// @notice Sets a season to a refunding state
  /// @param token the contract to set into a refunding state
  /// @param seasonId the season to set into a refunding state
  function startRefund(address token, uint256 seasonId) external;

  /// @notice Reduce the refundable amount for a project season
  /// @dev Can only be called from the claims contract
  /// @param token the token address of the project
  /// @param seasonId the seasonId
  /// @param amount the amount to reduce the project's refundable amount by
  function reduceRefundableAmount(address token, uint256 seasonId, uint256 amount) external;

  /// @notice Increment the total deposited token of the project
  /// @dev Can only be called from the claims contract
  /// @param token the token address of the project
  /// @param amount to increment totalDeposited
  function addTotalDeposited(address token, uint256 amount) external returns (uint256);

  /// @notice Factory admins can schedule token withdrawals for the project.
  /// @dev Only callable by the admin of the BUILDFactory
  /// @param token address of the project token
  /// @param recipient The withdrawal address
  /// @param amount The withdrawal amount
  function scheduleWithdraw(address token, address recipient, uint256 amount) external;

  /// @notice Factory admins can cancel previously scheduled token withdrawals
  /// @dev Only callable by the admin of the BUILDFactory
  /// @param token address of the project token
  function cancelWithdraw(
    address token
  ) external;

  /// @notice Project admins can execute scheduled token withdrawals from the claim contract
  /// @dev Only callable by the claims contract
  /// @param token address of the project token
  /// @return Withdrawal The withdrawal recipient and amount
  /// @return uint256 The updated total withdrawn amount of the project
  function executeWithdraw(
    address token
  ) external returns (Withdrawal memory, uint256);

  /// @notice Returns all projects
  /// @return The list of project token addresses
  function getProjects() external view returns (address[] memory);

  /// @notice Returns the upper bounds for the unlock duration and delay
  /// @return UnlockMaxConfigs The max unlock duration and max unlock delay
  function getUnlockConfigMaxValues() external view returns (UnlockMaxConfigs memory);

  /// @notice Returns a project config
  /// @param token The project token address
  /// @return A project config consisting of the project’s admin address and the claim contract
  /// address
  function getProjectConfig(
    address token
  ) external view returns (ProjectConfig memory);

  /// @notice Returns a season config
  /// @param seasonId The season id
  /// @return startTime The season's unlock start time
  function getSeasonUnlockStartTime(
    uint256 seasonId
  ) external view returns (uint256 startTime);

  /// @notice Returns a project season config
  /// @param token The project token address
  /// @param seasonId The season id
  /// @return projectSeasonConfig project season config consisting of the token amount, unlock ends
  /// at, total credits,
  /// and merkle root
  /// @return unlockEndsAt The season's unlock end time
  function getProjectSeasonConfig(
    address token,
    uint256 seasonId
  ) external view returns (ProjectSeasonConfig memory projectSeasonConfig, uint256 unlockEndsAt);

  /// @notice Returns the current pause state of a claim contract for a specific project
  /// @dev A claim contract is considered paused when the factory is paused (emergencyPause) or the
  /// claim contract is paused individually (pauseClaimContract)
  /// @param token The project token address
  /// @return bool The current pause state
  function isClaimContractPaused(
    address token
  ) external view returns (bool);

  /// @notice Returns the refunding state of a season contract
  /// @param token the address of the token
  /// @param seasonId the id of the season
  /// @return bool The current refunding state of season
  function isRefunding(address token, uint256 seasonId) external view returns (bool);

  /// @notice Get the token amount struct of the project
  /// @param token the token address of the project
  /// @return TokenAmounts the token amount struct for the project
  function getTokenAmounts(
    address token
  ) external view returns (TokenAmounts memory);

  /// @notice Calculate the max available token amount of the project
  /// @param token the token address of the project
  /// @return uint256 maxAvailable The maximum available amount to be allocated or withdrawn
  function calcMaxAvailableAmount(
    address token
  ) external view returns (uint256);

  /// @notice Get the refundable amount for a project season
  /// @param token the token address of the project
  /// @param seasonId the seasonId
  /// @return uint256 The refundable amount
  function getRefundableAmount(address token, uint256 seasonId) external view returns (uint256);

  /// @notice Returns parameters for a scheduled withdrawal, if any
  /// @param token address of the project token
  /// @return the withdrawal recipient address and amount
  function getScheduledWithdrawal(
    address token
  ) external view returns (Withdrawal memory);
}
