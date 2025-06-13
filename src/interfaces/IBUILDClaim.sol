// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BUILDFactory} from "../BUILDFactory.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IBUILDClaim is IERC165 {
  /// @notice this event is emitted when a token deposit is made
  /// @param token The token address
  /// @param sender The depositor address
  /// @param amount The deposit amount
  /// @param totalDeposit The cumulative amount deposited to this contract
  event Deposited(
    address indexed token, address indexed sender, uint256 amount, uint256 totalDeposit
  );

  /// @notice this event is emitted when a token withdrawal is made
  /// @param token The token address
  /// @param recipient The withdrawal address
  /// @param amount The withdrawal amount
  /// @param totalWithdrawn The cumulative amount withdrawn from this contract
  event Withdrawn(
    address indexed token, address indexed recipient, uint256 amount, uint256 totalWithdrawn
  );

  /// @notice this event is emitted when a claim is made
  /// @param user The user address
  /// @param seasonId The season id
  /// @param amount The claim amount
  /// @param isEarlyClaim The flag indicating the claim was an early vest
  /// @param earlyVestAmount The portion of claim amount that is early vested
  /// @param userClaimedInSeason The cumulative amount claimed by the user in the season
  /// @param totalClaimedInSeason The cumulative amount claimed by all users in the season
  /// @param totalLoyaltyAmount The cumulative amount in the loyalty pool in the season
  /// @param totalLoyaltyIneligibleAmount The cumulative amount of ineligible loyalty in the season
  event Claimed(
    address indexed user,
    uint256 seasonId,
    uint256 amount,
    bool isEarlyClaim,
    uint256 earlyVestAmount,
    uint256 userClaimedInSeason,
    uint256 totalClaimedInSeason,
    uint256 totalLoyaltyAmount,
    uint256 totalLoyaltyIneligibleAmount
  );

  /// @notice this error is thrown when an invalid merkle proof is provided
  error InvalidMerkleProof();

  /// @notice this error is thrown when a zero address is provided as the user address
  /// @param user The user address
  error InvalidUser(address user);

  /// @notice this error is thrown when the sender is not the user or their delegate and
  /// is trying to early claim
  /// @param msgSender The address of the sender
  error InvalidSender(address msgSender);

  /// @notice this error is thrown when the unlock period for a season has not started
  /// @param seasonId The season id
  error UnlockNotStarted(uint256 seasonId);

  /// @notice This error is thrown when the user is trying to early claim tokens for a season that
  /// has finished vesting
  /// @param user The user address
  /// @param seasonId The season id
  error InvalidEarlyClaim(address user, uint256 seasonId);

  /// @notice This error is thrown when the expected token amount wasn't transferred after a deposit
  /// @param balanceBefore The balance before the deposit
  /// @param balanceAfter The balance after the deposit
  error InvalidDeposit(uint256 balanceBefore, uint256 balanceAfter);

  /// @notice This struct defines the parameters for claiming tokens
  struct ClaimParams {
    uint32 seasonId; // ────╮ The season id
    bool isEarlyClaim; // ──╯ is Early Claim
    bytes32[] proof; // The merkle proof for the user's token amount for a season
    uint256 maxTokenAmount; // The total token amount user can get for a season
    uint256 salt; // A randomly generated salt to prevent brute-force guessing of merkle proofs
  }

  /// @notice this struct defines all the necessary state of the claimable tokens for a user
  struct ClaimableState {
    uint256 base; // The base amount of tokens that can be claimed
    uint256 bonus; // The bonus amount of tokens that can be claimed
    uint256 vested; // The amount of bonus tokens that are vested
    uint256 claimable; // The total amount of tokens that can be claimed, roughly base + vested
    uint256 earlyVestableBonus; // The amount of bonus tokens that are not vested and can be claimed
      // early
    uint256 loyaltyBonus; // The amount of loyalty bonus tokens that can be claimed
    uint256 claimed; // The amount of tokens that have already been claimed by this user
      // earlyVestClaimable is derivable by claimable + earlyVestableBonus
  }

  /// @notice this struct defines the global state of a season
  struct GlobalState {
    uint256 totalLoyalty; // The total amount of loyalty bonus tokens that can be claimed
    uint256 totalLoyaltyIneligible; // The total amount of regular claim tokens that are factored
      // out of consideration for totalLoyalty allocation.
      // This is the sum of all max token amounts of users who have early claimed
    uint256 totalClaimed; // The total amount of tokens that have been claimed by all users
  }

  /// @notice The user state for a season
  struct UserState {
    uint248 claimed; // ───────╮ The amount of tokens that have already been claimed by this user
    bool hasEarlyClaimed; // ──╯ Whether the user has already claimed tokens for this season
  }

  /// @notice This struct defines the user and season id for batch queries
  struct UserSeasonId {
    /// @notice The user address
    address user;
    /// @notice The season id
    uint256 seasonId;
  }

  /// @notice Project admins can deposit tokens for the program.
  /// @param amount The deposit amount
  function deposit(
    uint256 amount
  ) external;

  /// @notice Project admins can execute the scheduled token withdrawal
  function withdraw() external;

  /// @notice Calculates the unlocked tokens for a particular user and transfers the tokens to the
  /// user.
  /// The user must provide a valid merkle proof and total token amount they will get after unlock
  /// finishes for each season they want to claim for.
  /// This function is to be used by EOAs when they claim from a single BUILDClaim contract, as well
  /// as by multisig wallets when they claim from a single BUILDClaim contract or batch claim from
  /// multiple BUILDClaim contracts.
  /// @param user The address of the user claiming the tokens. This should match the msg.sender.
  /// @param params Claim params including the season IDs, proofs, salts, and max token amounts
  function claim(address user, ClaimParams[] calldata params) external;

  /// @notice Returns the BUILDFactory that was used to deploy the claim contract
  /// @return the factory address
  function getFactory() external view returns (BUILDFactory);

  /// @notice Returns the project token
  /// @return the token address
  function getToken() external view returns (IERC20);

  /// @notice Calculates the global state for a season
  /// @param seasonId The season id
  /// @return GlobalState The global state for the season
  function getGlobalState(
    uint256 seasonId
  ) external view returns (GlobalState memory);

  /// @notice Returns the user state for a list of seasons
  /// @param usersAndSeasonIds The list of user address + season id
  /// @return UserState[] The user's claimed amount for list of seasons
  function getUserState(
    UserSeasonId[] calldata usersAndSeasonIds
  ) external view returns (UserState[] memory);

  /// @notice Calculates the various amounts of claiming related tokens for a user
  /// @param user The user address
  /// @param seasonId The season id
  /// @param maxTokenAmount The user's total claimable token amount for the season
  /// @return ClaimableState The various amounts of tokens related to claiming for a user
  function getCurrentClaimValues(
    address user,
    uint256 seasonId,
    uint256 maxTokenAmount
  ) external view returns (ClaimableState memory);
}
