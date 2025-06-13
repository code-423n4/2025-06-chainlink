// SPDX-License-Identifier: MIT
// solhint-disable no-console
pragma solidity 0.8.26;

import {BaseTest} from "./BaseTest.t.sol";
import {IBUILDClaim} from "../src/interfaces/IBUILDClaim.sol";
import {IBUILDFactory} from "../src/interfaces/IBUILDFactory.sol";
// solhint-disable-next-line no-global-import
import "forge-std/console.sol";

contract ScenarioBuilder is BaseTest {
  error NoSnapshotAvailableForIndex(uint256 index);
  error SnapshotValueDoesNotMatchExpectation(string key, uint256 snapshotVal, uint256 assertVal);
  error InvalidField(Field field);

  mapping(address user => mapping(uint256 season => User)) internal s_users;

  struct User {
    bytes32[] proof;
    bytes32[] proofEarly;
    uint256 maxTokenAmount;
    uint256 salt;
  }

  struct Assertion {
    uint256 snapshotIndex;
    address user;
    uint256 season;
    Field key;
    uint256 value;
  }

  /// @notice Field defines possible options for parameter mapping
  enum Field {
    CLAIMED,
    CLAIMABLE,
    LOYALTY,
    VESTED,
    TOTAL_CLAIMED,
    TOTAL_LOYALTY_INELIGIBLE,
    TOTAL_LOYALTY,
    TOTAL_REFUNDABLE
  }

  function _fieldToString(
    Field field
  ) internal pure returns (string memory) {
    if (field == Field.CLAIMED) {
      return "claimed";
    } else if (field == Field.CLAIMABLE) {
      return "claimable";
    } else if (field == Field.LOYALTY) {
      return "loyalty";
    } else if (field == Field.VESTED) {
      return "vested";
    } else if (field == Field.TOTAL_CLAIMED) {
      return "total_claimed";
    } else if (field == Field.TOTAL_LOYALTY_INELIGIBLE) {
      return "total_loyalty_ineligible";
    } else if (field == Field.TOTAL_LOYALTY) {
      return "total_loyalty";
    } else if (field == Field.TOTAL_REFUNDABLE) {
      return "total_refundable";
    }
    revert InvalidField(field);
  }

  // using string parameter to be able to validate specific parameters (similar to providing a path)
  mapping(address user => mapping(uint256 season => mapping(Field key => uint256[] snapshotValues)))
    private s_snapshots;
  Assertion[] private s_assertions;
  uint8 private s_snapshotCount;

  /// @notice Validates snapshot assertions after the wrapped function executes.
  /// @dev This modifier performs post-call snapshot value assertions based on the `s_assertions`
  /// array.
  /// It checks that the expected snapshot values match the stored values at specific indices,
  /// and reverts if any assertion fails. It also logs validation info using `console.log`.
  ///
  /// Reverts with:
  /// - `NoSnapshotAvailableForIndex` if the snapshot index is out of bounds.
  /// - `SnapshotValueDoesNotMatchExpectation` if the expected value does not match the actual
  /// value.
  /// @param skipClaims Skip ensuring that all claims are able to be processed
  function _validateSnapshots(
    bool skipClaims
  ) internal {
    // skip past end of season 1 + season 2 to ensure full unlock
    _skipUnlockEndedForSeason1();
    _skipUnlockEndedForSeason2();
    address[] memory users = _getUsers();
    uint32[] memory seasons = _getSeasons();
    uint256 nonRefundable;
    for (uint256 i = 0; i < seasons.length; i++) {
      uint32 season = seasons[i];
      // skip if season has not been set
      if (s_factory.getSeasonUnlockStartTime(season) == 0) {
        continue;
      }

      for (uint256 j = 0; j < users.length; j++) {
        address user = users[j];
        if (!skipClaims) {
          // ensure that all claims still work after previous interactions
          // this may result in 0 claimable tokens
          // if there are claimable tokens, this ensures that all claims can be fully processed
          _claim({user: user, season: season, isEarlyClaim: false});
        }
      }

      // start refunding for season
      _changePrank(ADMIN);
      if (!s_factory.isRefunding(address(s_token), season)) {
        s_factory.startRefund(address(s_token), season);
      }
      for (uint256 j = 0; j < users.length; j++) {
        address user = users[j];
        IBUILDClaim.ClaimableState memory state =
          s_claim.getCurrentClaimValues(user, season, s_users[user][season].maxTokenAmount);
        // track nonrefundable amounts (when user has already claimed before refunding starts)
        nonRefundable += state.claimable;
      }

      // ensure that unclaimed tokens for season can be withdrawn
      uint256 amount = s_factory.getRefundableAmount(address(s_token), season);
      if (amount != 0) {
        s_factory.scheduleWithdraw(address(s_token), PROJECT_ADMIN, amount);
        _changePrank(PROJECT_ADMIN);
        s_claim.withdraw();
      }
    }
    // validate actual token balance >= withdrawable + nonrefundable
    // account for leftover dust from rounding down
    assert(
      s_token.balanceOf(address(s_claim))
        - (s_factory.calcMaxAvailableAmount(address(s_token)) + nonRefundable) <= 1
    );

    if (s_assertions.length == 0) {
      console.log("No assertions to validate");
    }

    for (uint256 i = 0; i < s_assertions.length; i++) {
      Assertion memory a = s_assertions[i];

      uint256[] storage vs = s_snapshots[a.user][a.season][a.key];
      if (a.snapshotIndex >= vs.length) {
        revert NoSnapshotAvailableForIndex(a.snapshotIndex);
      }
      if (a.value != vs[a.snapshotIndex]) {
        revert SnapshotValueDoesNotMatchExpectation(
          _fieldToString(a.key), vs[a.snapshotIndex], a.value
        );
      }
      console.log("[validated] Snapshot %d, Season %d, User: %s", a.snapshotIndex, a.season, a.user);
      console.log("            %s = %d", _fieldToString(a.key), a.value);
    }
  }

  modifier validateSnapshots() {
    _;
    _validateSnapshots(false); // validate claiming for all users
  }

  modifier validateSnapshotsSkipClaims() {
    _;
    _validateSnapshots(true); // skip claiming again because of revert
  }

  constructor() {
    // s1
    s_users[USER_1][SEASON_ID_S1] = User({
      proof: MERKLE_PROOF_P1_S1_U1,
      proofEarly: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1
    });
    s_users[USER_2][SEASON_ID_S1] = User({
      proof: MERKLE_PROOF_P1_S1_U2,
      proofEarly: MERKLE_PROOF_P1_S1_U2_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U2,
      salt: SALT_U2
    });
    s_users[USER_MSIG][SEASON_ID_S1] = User({
      proof: MERKLE_PROOF_P1_S1_MSIG,
      proofEarly: MERKLE_PROOF_P1_S1_MSIG_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_MSIG,
      salt: SALT_MSIG
    });

    // s2
    s_users[USER_1][SEASON_ID_S2] = User({
      proof: MERKLE_PROOF_P1_S2_U1,
      proofEarly: MERKLE_PROOF_P1_S2_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S2_U1,
      salt: SALT_U1
    });
    s_users[USER_2][SEASON_ID_S2] = User({
      proof: MERKLE_PROOF_P1_S2_U2,
      proofEarly: MERKLE_PROOF_P1_S2_U2_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S2_U2,
      salt: SALT_U2
    });
    s_users[USER_MSIG][SEASON_ID_S2] = User({
      proof: MERKLE_PROOF_P1_S2_MSIG,
      proofEarly: MERKLE_PROOF_P1_S2_MSIG_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S2_MSIG,
      salt: SALT_MSIG
    });
  }

  /// @notice Records an expected snapshot value for a user, season, and key at a specific index.
  /// @dev Appends an `Assertion` to `s_assertions`, which will later be validated by the
  /// `validateSnapshots` modifier.
  /// @param snapshotIndex The index of the snapshot to assert against.
  /// @param user The address of the user whose snapshot is being asserted.
  /// @param season The season identifier associated with the snapshot.
  /// @param key The key used to identify the snapshot value (e.g., "balance").
  /// @param value The expected value at the given snapshot index.
  function _assert(
    uint256 snapshotIndex,
    address user,
    uint256 season,
    Field key,
    uint256 value
  ) internal {
    s_assertions.push(Assertion(snapshotIndex, user, season, key, value));
  }

  /// @notice Captures and logs the current state of claims for all users and seasons.
  /// @dev Iterates through all configured seasons and users to snapshot key state values such as
  /// total claimed, claimed per user, and claimable per user. This data is stored in `s_snapshots`
  /// and logged to the console for debugging and validation purposes.
  ///
  /// Skips any season where the unlock start time is not set.
  function _snapshot() internal returns (uint8 snapshotIndex) {
    uint32[] memory seasons = _getSeasons();
    address[] memory users = _getUsers();

    console.log("///////////////////////////");
    console.log("//  Timestamp: %d   //", block.timestamp);
    console.log("///////////////////////////");

    for (uint256 i = 0; i < seasons.length; i++) {
      uint256 season = seasons[i];

      // skip if season has not been set
      if (s_factory.getSeasonUnlockStartTime(season) == 0) {
        continue;
      }

      console.log("------------------- SEASON %d -------------------", season);

      // snapshot global state
      // snapshot contract state

      IBUILDClaim.GlobalState memory globalState = s_claim.getGlobalState(season);
      uint256 refundable = s_factory.getRefundableAmount(address(s_token), season);

      s_snapshots[address(s_claim)][season][Field.TOTAL_CLAIMED].push(globalState.totalClaimed);
      s_snapshots[address(s_claim)][season][Field.TOTAL_LOYALTY_INELIGIBLE].push(
        globalState.totalLoyaltyIneligible
      );
      s_snapshots[address(s_claim)][season][Field.TOTAL_LOYALTY].push(globalState.totalLoyalty);
      s_snapshots[address(s_claim)][season][Field.TOTAL_REFUNDABLE].push(refundable);

      console.log("Contract:                ", address(s_claim));
      console.log("Total Claimed:           ", globalState.totalClaimed);
      console.log("Total Loyalty Ineligible:", globalState.totalLoyaltyIneligible);
      console.log("Total Loyalty:           ", globalState.totalLoyalty);
      console.log("Total Refundable:        ", refundable);
      console.log("-");

      _snapshotUsers(users, season);
    }
    console.log("--------------------------------------------------\n");
    s_snapshotCount++;
    return s_snapshotCount - 1;
  }

  function _snapshotUsers(address[] memory users, uint256 season) internal {
    // snapshot each user
    for (uint256 j = 0; j < users.length; j++) {
      address user = users[j];
      address token = address(s_token); // address(s_claim.getToken());

      IBUILDClaim.ClaimableState memory claimableState =
        s_claim.getCurrentClaimValues(user, season, s_users[user][season].maxTokenAmount);

      s_snapshots[user][season][Field.CLAIMED].push(claimableState.claimed);
      s_snapshots[user][season][Field.CLAIMABLE].push(claimableState.claimable);
      s_snapshots[user][season][Field.LOYALTY].push(claimableState.loyaltyBonus);
      s_snapshots[user][season][Field.VESTED].push(claimableState.vested);

      console.log("User:               ", user);
      console.log("Token:              ", token);
      console.log("Claimed:            ", claimableState.claimed);
      console.log("Claimable:          ", claimableState.claimable);
      console.log("Loyalty Bonus:      ", claimableState.loyaltyBonus);
      console.log("Vested:             ", claimableState.vested);
      console.log("-");
    }
  }

  /// @notice Internally performs a claim for the given user and season, optionally handling
  /// expected reverts.
  /// @dev This version allows for specifying a `revertReason` to test or expect a revert during
  /// claim execution (useful for negative tests).
  /// @param user The address of the user attempting to claim.
  /// @param season The ID of the season for which the claim is being made.
  /// @param isEarlyClaim Flag indicating whether the claim is considered an early claim.
  /// @param revertReason If non-empty, the function will expect a revert with the given reason.
  function _claim(
    address user,
    uint32 season,
    bool isEarlyClaim,
    bytes memory revertReason
  ) internal {
    uint32[] memory seasons = new uint32[](1);
    seasons[0] = season;
    _claim(user, seasons, isEarlyClaim, revertReason);
  }

  /// @notice Internally performs a claim for the given user and season.
  /// @dev This version assumes no revert is expected; it calls the internal `_claim` with an empty
  /// revert reason.
  /// @param user The address of the user attempting to claim.
  /// @param season The ID of the season for which the claim is being made.
  /// @param isEarlyClaim Flag indicating whether the claim is considered an early claim.
  function _claim(address user, uint32 season, bool isEarlyClaim) internal {
    _claim(user, season, isEarlyClaim, "");
  }

  /// @notice Internally performs a claim for the given user and season, optionally handling
  /// expected reverts.
  /// @dev This version supports multiple seasons
  /// @param user The address of the user attempting to claim.
  /// @param seasons The IDs of the seasons for which the claim is being made.
  /// @param isEarlyClaim Flag indicating whether the claim is considered an early claim.
  function _claim(address user, uint32[] memory seasons, bool isEarlyClaim) internal {
    _claim(user, seasons, isEarlyClaim, "");
  }

  /// @notice Internally performs a claim for the given user and season, optionally handling
  /// expected reverts.
  /// @dev This version supports multiple seasons and allows for specifying a `revertReason` to test
  /// or expect a revert during claim execution (useful for negative tests).
  /// @param user The address of the user attempting to claim.
  /// @param seasons The IDs of the seasons for which the claim is being made.
  /// @param isEarlyClaim Flag indicating whether the claim is considered an early claim.
  /// @param revertReason If non-empty, the function will expect a revert with the given reason.
  function _claim(
    address user,
    uint32[] memory seasons,
    bool isEarlyClaim,
    bytes memory revertReason
  ) internal {
    _changePrank(user);
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](seasons.length);

    for (uint256 i = 0; i < seasons.length; i++) {
      uint32 season = seasons[i];
      params[i] = IBUILDClaim.ClaimParams({
        seasonId: season,
        proof: isEarlyClaim ? s_users[user][season].proofEarly : s_users[user][season].proof,
        maxTokenAmount: s_users[user][season].maxTokenAmount,
        salt: s_users[user][season].salt,
        isEarlyClaim: isEarlyClaim
      });
    }

    if (revertReason.length != 0) {
      vm.expectRevert(revertReason);
    }
    s_claim.claim(user, params);
  }

  /// @notice Calculates the fully vested claim given the current loyalty pool
  /// @dev This calls _calculateLoyalty but looks up values based on the user and season
  /// for project 1
  /// @param user The address of the user for calculating the claim
  /// @param season The season for calculating the claim
  function _calculateClaimWithLoyalty(address user, uint256 season) internal view returns (uint256) {
    IBUILDClaim.GlobalState memory globalState = s_claim.getGlobalState(season);
    (IBUILDFactory.ProjectSeasonConfig memory config,) =
      s_factory.getProjectSeasonConfig(address(s_token), season);
    uint256 regularClaim = s_users[user][season].maxTokenAmount;

    return regularClaim
      + _calculateLoyalty(
        globalState.totalLoyalty,
        regularClaim,
        config.tokenAmount - globalState.totalLoyaltyIneligible
      );
  }

  function _skipTo(
    uint40 targetTime
  ) internal {
    uint256 currentTime = block.timestamp;
    assert(targetTime >= currentTime);
    skip(targetTime - currentTime + 1); // difference + immediate next second
  }

  // add this to be excluded from coverage report
  function test() public virtual override {}
}
