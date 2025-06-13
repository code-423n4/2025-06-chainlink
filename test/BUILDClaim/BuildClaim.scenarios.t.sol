// SPDX-License-Identifier: MIT
// solhint-disable no-console
pragma solidity 0.8.26;

import {ScenarioBuilder} from "../ScenarioBuilder.t.sol";
import {IBUILDClaim} from "../../src/interfaces/IBUILDClaim.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

// HOW TO USE
// The scenario builder is a set of functions that allow a user quickly define asserts and claim
// patterns, and will print out user readable snapshots in the terminal.
//
// Run with:
// [all scenarios] pnpm test:scenarios
// [specific] pnpm test:scenarios --match-test test_WhenTheUserUsesPattern_E_
contract BUILDClaimScenarios is ScenarioBuilder {
  modifier whenSingleUser() {
    _;
  }

  function test_WhenTheClaimPatternIs_n_n_n()
    external
    whenSingleUser
    whenSeason1IsSetup
    validateSnapshots
  {
    // it should do nothing and process no claims

    // attempt claim before unlock delay
    bytes memory revertReason =
      abi.encodeWithSelector(IBUILDClaim.UnlockNotStarted.selector, SEASON_ID_S1);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false, revertReason: revertReason});
    uint8 s0 = _snapshot(); // snapshot before unlock starts

    _skipUnlockEndedForSeason1();
    _assert(s0, address(s_claim), SEASON_ID_S1, Field.TOTAL_CLAIMED, 0);
    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMABLE, 0);
    _assert(s0, USER_1, SEASON_ID_S1, Field.LOYALTY, 0);
    _assert(s0, USER_1, SEASON_ID_S1, Field.VESTED, 0);
  }

  function test_WhenTheClaimPatternIs_n_n_E1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockEndedForProject1Season1
    validateSnapshots
  {
    // it should allow an early claim at unlock100 and ignore the early flag
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U1);
    _assert(s0, address(s_claim), SEASON_ID_S1, Field.TOTAL_LOYALTY, 0);
  }

  function test_WhenTheClaimPatternIs_n_n_R1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockEndedForProject1Season1
    validateSnapshots
  {
    // it should allow a regular claim at unlock100
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_n_E1_n()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockIsInHalfWayForSeason1
    validateSnapshots
  {
    // it should allow an early claim at unlock50
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_n_E1_E1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockIsInHalfWayForSeason1
    validateSnapshots
  {
    // it should allow claim at unlock100 with 0 amount
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();
    _skipUnlockEndedForSeason1();
    // attempt to early claim again, earlyClaim has not impact after unlock ended
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s1 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_n_E1_R1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockIsInHalfWayForSeason1
    validateSnapshots
  {
    // it should allow an early claim at unlock50 and a regular claim at unlock100
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();
    _skipUnlockHalfwayForSeason1(); // jump another t = 50%
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false}); // attempt to claim again
    uint8 s1 = _snapshot();

    // t = 50% through season
    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
    // as they are the first claim, there's no amounts in the loyalty pool for them.
    _assert(s0, USER_1, SEASON_ID_S1, Field.LOYALTY, 0);
    _assert(s0, USER_2, SEASON_ID_S1, Field.LOYALTY, 1446428571428571428);

    // t = 100% through season
    uint256 loyalty = MAX_TOKEN_AMOUNT_P1_S1_U1 - EARLY_CLAIM_HALF_P1_S1_U1;
    _assert(s1, USER_1, SEASON_ID_S1, Field.LOYALTY, 0);
    _assert(s1, address(s_claim), SEASON_ID_S1, Field.TOTAL_LOYALTY, loyalty);
    _assert(
      s1, address(s_claim), SEASON_ID_S1, Field.TOTAL_LOYALTY_INELIGIBLE, MAX_TOKEN_AMOUNT_P1_S1_U1
    );
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_n_R1_n()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockIsInHalfWayForSeason1
    validateSnapshots
  {
    // it should allow a regular claim at unlock50 only
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_HALF_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_n_R1_E1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockIsInHalfWayForSeason1
    validateSnapshots
  {
    // it should allow a regular claim at unlock50 and treat unlock100 early flag as ignored
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    _snapshot();
    _skipUnlockEndedForSeason1();
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_n_R1_R1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockIsInHalfWayForSeason1
    validateSnapshots
  {
    // it should allow regular claims at unlock50 and unlock100
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();
    _skipUnlockHalfwayForSeason1();
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s1 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_HALF_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_E1_n_n()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow an early claim at unlock0
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1);

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_E1_n_E1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow an early claim at unlock0 and ignore the early flag at unlock100
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint256 s1 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_E1_n_R1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow an early claim at unlock0 and return 0 for regular claim at unlock100
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint256 s1 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_E1_E1_n()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should revert at unlock50 because a second early claim is not allowed
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    bytes memory revertReason =
      abi.encodeWithSelector(IBUILDClaim.InvalidEarlyClaim.selector, USER_1, SEASON_ID_S1);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true, revertReason: revertReason});

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_E1_E1_E1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should revert at unlock50 because a second early claim is not allowed, and early flag at
    // unlock100 should be ignored
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    bytes memory revertReason =
      abi.encodeWithSelector(IBUILDClaim.InvalidEarlyClaim.selector, USER_1, SEASON_ID_S1);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true, revertReason: revertReason});
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s1 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_E1_E1_R1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should revert at unlock50 because a second early claim is not allowed, and it should allow
    // a regular claim at unlock100
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    bytes memory revertReason =
      abi.encodeWithSelector(IBUILDClaim.InvalidEarlyClaim.selector, USER_1, SEASON_ID_S1);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true, revertReason: revertReason});
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s1 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_E1_R1_n()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow an early claim at unlock0 and block the regular claim at unlock50
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s1 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_E1_R1_E1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow an early claim at unlock0, ignore regular at unlock50, and ignore early flag
    // at unlock100
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s1 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s2 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
    _assert(s2, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_E1_R1_R1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow an early claim at unlock0 and ignore all claims afterward
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s1 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s2 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
    _assert(s2, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_R1_n_n()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow a regular claim at unlock0 with 0 claimed amount
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_START_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_R1_n_E1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow a regular claim at unlock0, and ignore early claim flag at unlock100
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s1 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_START_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_R1_n_R1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow regular claims at unlock0 and unlock100
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s1 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_START_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_R1_E1_n()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow a regular claim at unlock0 and an early claim at unlock50
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s1 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_START_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_R1_E1_E1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow a regular claim at unlock0, early at unlock50, and ignore early flag on
    // unlock100
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s1 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s2 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_START_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
    _assert(s2, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_R1_E1_R1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow a regular claim at unlock0, early at unlock50, and a regular claim at
    // unlock100
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s1 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s2 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_START_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
    _assert(s2, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_R1_R1_n()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow regular claims at unlock0 and unlock50
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s1 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_START_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_HALF_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_R1_R1_E1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow regular claims at unlock0, unlock50, and ignore early flag at unlock100
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s1 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s2 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_START_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_HALF_P1_S1_U1);
    _assert(s2, USER_1, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_R1_R1_R1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow regular claims at all three slots
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s1 = _snapshot();
    skip(UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s2 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_START_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_HALF_P1_S1_U1);
    _assert(s2, USER_1, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_n_n_R1ForMultipleSeasons()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenSeason2IsSetup
    validateSnapshots
  {
    // it should allow regular claims
    _skipUnlockEndedForSeason1();
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();
    _skipUnlockEndedForSeason2();
    _claim({user: USER_MSIG, season: SEASON_ID_S2, isEarlyClaim: false});
    uint8 s1 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U1);
    _assert(s1, USER_MSIG, SEASON_ID_S2, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S2_MSIG);
  }

  function test_WhenTheClaimPatternIs_R1E1_n_n()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow both claims
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s1 = _snapshot();

    // only base claim amount available right when unlock is done
    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_START_P1_S1_U1);
    // early vesting causes remaining tokens to be contributed to loyalty pool
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_n_R1E1_n()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockIsInHalfWayForSeason1
    validateSnapshots
  {
    // it should allow both claims
    // in same block (no time passes)
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s1 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_HALF_P1_S1_U1);
    _assert(s0, address(s_claim), SEASON_ID_S1, Field.TOTAL_LOYALTY, 0);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
    _assert(
      s1, address(s_claim), SEASON_ID_S1, Field.TOTAL_LOYALTY_INELIGIBLE, MAX_TOKEN_AMOUNT_P1_S1_U1
    );
    _assert(
      s1,
      address(s_claim),
      SEASON_ID_S1,
      Field.TOTAL_LOYALTY,
      MAX_TOKEN_AMOUNT_P1_S1_U1 - EARLY_CLAIM_HALF_P1_S1_U1
    );
  }

  function test_WhenTheClaimPatternIs_n_n_R1E1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockEndedForProject1Season1
    validateSnapshots
  {
    // it should allow both claims
    // it should allow a regular claim at unlock100
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();
    // it should skip the early claim
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s1 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_E1R1_n_n()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow both claims
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});

    // early vesting causes remaining tokens to be contributed to loyalty pool
    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_n_E1R1_n()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockIsInHalfWayForSeason1
    validateSnapshots
  {
    // it should allow both claims
    // in same block (no time passes)
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
    _assert(
      s0, address(s_claim), SEASON_ID_S1, Field.TOTAL_LOYALTY_INELIGIBLE, MAX_TOKEN_AMOUNT_P1_S1_U1
    );
    _assert(
      s0,
      address(s_claim),
      SEASON_ID_S1,
      Field.TOTAL_LOYALTY,
      MAX_TOKEN_AMOUNT_P1_S1_U1 - EARLY_CLAIM_HALF_P1_S1_U1
    );
  }

  function test_WhenTheClaimPatternIs_n_n_E1R1()
    external
    whenSingleUser
    whenSeason1IsSetup
    whenTheUnlockEndedForProject1Season1
    validateSnapshots
  {
    // it should allow both claims
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();

    // early claim becomes regular claim
    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U1);
  }

  function test_WhenTheClaimPatternIs_n_R1E1_nAndVestRatioIs0()
    external
    whenSingleUser
    whenSeason1IsSetup
    validateSnapshots
  {
    // it should skip the early claim
    // early vest reward is always 0
    // allows for reaching the `maxTokenAmount - claimedAmount - forfeitedAmount == 0` conditional
    // to skip the early claim
    _changePrank(ADMIN);
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: TOKEN_AMOUNT_P1_S1,
        baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: UNLOCK_DURATION_S1,
        merkleRoot: MERKLE_ROOT_P1_S1,
        earlyVestRatioMinBps: 0,
        earlyVestRatioMaxBps: 0,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);

    _skipUnlockHalfwayForSeason1();
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true}); // yields 0 tokens
      // so the claim is skipped
    uint8 s1 = _snapshot();
    _skipUnlockEndedForSeason1();
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false}); // can still claim
    uint8 s2 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_HALF_P1_S1_U1);
    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMABLE, 0);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_HALF_P1_S1_U1);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMABLE, 0);
    _assert(s2, USER_1, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U1);
    _assert(s2, USER_1, SEASON_ID_S1, Field.CLAIMABLE, 0);
  }

  function test_RevertWhen_TheUserAttemptsToClaimAfterRefundingHasStarted()
    external
    whenSeason1IsSetup
    whenTheUnlockIsInHalfWayForSeason1
    whenProjectSeasonIsRefunding
    validateSnapshotsSkipClaims
  {
    // it should revert
    bytes memory revertReason = abi.encodeWithSelector(
      IBUILDFactory.ProjectSeasonIsRefunding.selector, address(s_token), SEASON_ID_S1
    );
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true, revertReason: revertReason});
    uint8 s0 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, 0);
    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMABLE, 0);
  }

  modifier whenMultiUser() {
    _;
  }

  function test_WhenTheClaimPatternIs_n_E1R2_R1R2()
    external
    whenMultiUser
    whenSeason1IsSetup
    whenTheUnlockIsInHalfWayForSeason1
    validateSnapshots
  {
    // it should allow all claims
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    _claim({user: USER_2, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();
    _skipUnlockEndedForSeason1();
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    _claim({user: USER_2, season: SEASON_ID_S1, isEarlyClaim: false});
    uint256 s1 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
    _assert(s0, USER_2, SEASON_ID_S1, Field.CLAIMED, CLAIM_HALF_P1_S1_U2);
    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
    uint256 totalU2 = _calculateClaimWithLoyalty(USER_2, SEASON_ID_S1);
    _assert(s1, USER_2, SEASON_ID_S1, Field.CLAIMED, totalU2);
    _assert(
      s1, address(s_claim), SEASON_ID_S1, Field.TOTAL_LOYALTY_INELIGIBLE, MAX_TOKEN_AMOUNT_P1_S1_U1
    );
    _assert(
      s1,
      address(s_claim),
      SEASON_ID_S1,
      Field.TOTAL_LOYALTY,
      MAX_TOKEN_AMOUNT_P1_S1_U1 - EARLY_CLAIM_HALF_P1_S1_U1
    );
    _assert(
      s1, address(s_claim), SEASON_ID_S1, Field.TOTAL_LOYALTY_INELIGIBLE, MAX_TOKEN_AMOUNT_P1_S1_U1
    );
  }

  function test_WhenTheClaimPatternIs_n_E1R2_n()
    external
    whenMultiUser
    whenSeason1IsSetup
    whenTheUnlockIsInHalfWayForSeason1
    validateSnapshotsSkipClaims
  {
    _claimPattern_n_E1R2_n();
  }

  function _claimPattern_n_E1R2_n() internal {
    // it should properly track refundable amounts
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    _claim({user: USER_2, season: SEASON_ID_S1, isEarlyClaim: false});
    _skipUnlockEndedForSeason1();
    _refundP1(SEASON_ID_S1);
    uint8 s0 = _snapshot();

    // early claimed - no further tokens to be claimed
    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMABLE, 0);

    // regular claimed - can still claim after
    _assert(s0, USER_2, SEASON_ID_S1, Field.CLAIMED, CLAIM_HALF_P1_S1_U2);
    _assert(
      s0,
      USER_2,
      SEASON_ID_S1,
      Field.CLAIMABLE,
      _calculateClaimWithLoyalty(USER_2, SEASON_ID_S1) - CLAIM_HALF_P1_S1_U2
    );

    // no claim - can no longer claim after refund
    _assert(s0, USER_MSIG, SEASON_ID_S1, Field.CLAIMED, 0);
    _assert(s0, USER_MSIG, SEASON_ID_S1, Field.CLAIMABLE, 0);

    // refundable amounts
    _assert(
      s0,
      address(s_claim),
      SEASON_ID_S1,
      Field.TOTAL_REFUNDABLE,
      _calculateClaimWithLoyalty(USER_MSIG, SEASON_ID_S1)
    );
  }

  function test_WhenTheClaimPatternIs_n_E1R2_n_R1R2RM()
    external
    whenMultiUser
    whenSeason1IsSetup
    whenTheUnlockIsInHalfWayForSeason1
    validateSnapshotsSkipClaims
  {
    // it should allow claims after refund for USER_2
    _claimPattern_n_E1R2_n();

    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false}); // zero-claimable
    _claim({user: USER_2, season: SEASON_ID_S1, isEarlyClaim: false}); // has claimable tokens
    bytes memory revertReason = abi.encodeWithSelector(
      IBUILDFactory.ProjectSeasonIsRefunding.selector, address(s_token), SEASON_ID_S1
    );
    _claim({user: USER_MSIG, season: SEASON_ID_S1, isEarlyClaim: false, revertReason: revertReason}); // missed
      // out on claiming
    uint8 s0 = _snapshot();
    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
    _assert(
      s0, USER_2, SEASON_ID_S1, Field.CLAIMED, _calculateClaimWithLoyalty(USER_2, SEASON_ID_S1)
    );
  }

  function test_WhenTheClaimPatternIs_R1R2RM_n_nAndBaseTokenIs100()
    external
    whenMultiUser
    whenSeason1IsSetup
    validateSnapshots
  {
    // it should allow for instant airdrop
    _allUsersClaimWithMaxBaseTokens({isEarlyClaim: false});
  }

  function _allUsersClaimWithMaxBaseTokens(
    bool isEarlyClaim
  ) internal {
    _changePrank(ADMIN);
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: TOKEN_AMOUNT_P1_S1,
        baseTokenClaimBps: MAX_BASE_TOKEN_CLAIM_PERCENTAGE,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 1,
        merkleRoot: MERKLE_ROOT_P1_S1,
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S1,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S1,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);

    skip(UNLOCK_START_TIME_S1 + UNLOCK_DELAY_P1_S1);

    // instantly claimable after unlock delay
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: isEarlyClaim});
    _claim({user: USER_2, season: SEASON_ID_S1, isEarlyClaim: isEarlyClaim});
    _claim({user: USER_MSIG, season: SEASON_ID_S1, isEarlyClaim: isEarlyClaim});
    uint256 s0 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U1);
    _assert(s0, USER_2, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U2);
    _assert(s0, USER_MSIG, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_MSIG);
  }

  function test_WhenTheClaimPatternIs_E1E2EM_n_n()
    external
    whenMultiUser
    whenSeason1IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow early claims for all users
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    _claim({user: USER_2, season: SEASON_ID_S1, isEarlyClaim: true});
    _claim({user: USER_MSIG, season: SEASON_ID_S1, isEarlyClaim: true});
    uint256 s0 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);
    _assert(s0, USER_2, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U2);
    _assert(s0, USER_MSIG, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_MSIG);
  }

  function test_WhenTheClaimPatternIs_E1E2EM_n_nAnsBaseTokenIs100()
    external
    whenMultiUser
    whenSeason1IsSetup
    validateSnapshots
  {
    // it should allow for instant airdrop regardless of early claim
    _allUsersClaimWithMaxBaseTokens({isEarlyClaim: true});
  }

  modifier whenMultiUserMultiSeason() {
    _;
  }

  function test_WhenTheClaimPatternIsS1_n_nR1R2RMAndS2_n_n_R1R2RM()
    external
    whenMultiUserMultiSeason
    whenSeason1IsSetup
    whenSeason2IsSetup
    validateSnapshots
  {
    // it should allow early claims for all seasons in single transaction per user
    _skipTo(UNLOCK_START_TIME_S2 + UNLOCK_DELAY_P1_S2 + UNLOCK_DURATION_S2);
    _claim({user: USER_1, seasons: _getSeasons(), isEarlyClaim: true});
    _claim({user: USER_2, seasons: _getSeasons(), isEarlyClaim: true});
    _claim({user: USER_MSIG, seasons: _getSeasons(), isEarlyClaim: true});
    uint256 s0 = _snapshot();

    // validate that all users regular claimed
    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U1);
    _assert(s0, USER_2, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_U2);
    _assert(s0, USER_MSIG, SEASON_ID_S1, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S1_MSIG);
    _assert(s0, USER_1, SEASON_ID_S2, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S2_U1);
    _assert(s0, USER_2, SEASON_ID_S2, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S2_U2);
    _assert(s0, USER_MSIG, SEASON_ID_S2, Field.CLAIMED, MAX_TOKEN_AMOUNT_P1_S2_MSIG);
  }

  function test_WhenTheClaimPatternIsS1_n_E1E2EM_nAndS2_E1E2EM_n_n()
    external
    whenMultiUserMultiSeason
    whenSeason1IsSetup
    whenSeason2IsSetup
    validateSnapshots
  {
    // it should allow early claims for all seasons in single transaction per user
    _skipTo(UNLOCK_START_TIME_S2 + UNLOCK_DELAY_P1_S2);
    _claim({user: USER_1, seasons: _getSeasons(), isEarlyClaim: true});
    _claim({user: USER_2, seasons: _getSeasons(), isEarlyClaim: true});
    _claim({user: USER_MSIG, seasons: _getSeasons(), isEarlyClaim: true});
    uint256 s0 = _snapshot();

    // validate that all users early claimed
    // season 1 claim is not at unlock 50%
    _assert(
      s0,
      address(s_claim),
      SEASON_ID_S1,
      Field.TOTAL_LOYALTY_INELIGIBLE,
      MAX_TOKEN_AMOUNT_P1_S1_U1 + MAX_TOKEN_AMOUNT_P1_S1_U2 + MAX_TOKEN_AMOUNT_P1_S1_MSIG
    );
    _assert(
      s0,
      address(s_claim),
      SEASON_ID_S2,
      Field.TOTAL_LOYALTY_INELIGIBLE,
      MAX_TOKEN_AMOUNT_P1_S2_U1 + MAX_TOKEN_AMOUNT_P1_S2_U2 + MAX_TOKEN_AMOUNT_P1_S2_MSIG
    );
  }

  function test_WhenTheClaimPatternIsS1_n_n_E1E2EMAndS2_n_E1E2EM_n()
    external
    whenMultiUserMultiSeason
    whenSeason1IsSetup
    whenSeason2IsSetup
    validateSnapshots
  {
    // it should allow claims for all seasons in single transaction per user
    _skipTo(UNLOCK_START_TIME_S2 + UNLOCK_DELAY_P1_S2 + UNLOCK_DURATION_S2 / 2);
    _claim({user: USER_1, seasons: _getSeasons(), isEarlyClaim: true});
    _claim({user: USER_2, seasons: _getSeasons(), isEarlyClaim: true});
    _claim({user: USER_MSIG, seasons: _getSeasons(), isEarlyClaim: true});
    uint256 s0 = _snapshot();

    // validate that all users regular claimed in season 1 and all users early claimed in season 2
    _assert(s0, address(s_claim), SEASON_ID_S1, Field.TOTAL_LOYALTY_INELIGIBLE, 0);
    _assert(
      s0,
      address(s_claim),
      SEASON_ID_S2,
      Field.TOTAL_LOYALTY_INELIGIBLE,
      MAX_TOKEN_AMOUNT_P1_S2_U1 + MAX_TOKEN_AMOUNT_P1_S2_U2 + MAX_TOKEN_AMOUNT_P1_S2_MSIG
    );
  }

  function test_WhenTheClaimPatternIsS1_E1R2_R2_R2RMAndS2_E1_E2_EM()
    external
    whenMultiUserMultiSeason
    whenSeason1IsSetup
    whenSeason2IsSetup
    whenTheUnlockDelayHasEndedForSeason1
    validateSnapshots
  {
    // it should allow all claims

    // season 1: unlock 0%
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    _claim({user: USER_2, season: SEASON_ID_S1, isEarlyClaim: false});
    uint256 s0 = _snapshot();
    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_START_P1_S1_U1);

    // season 1: unlock 50%
    _skipTo(UNLOCK_START_TIME_S1 + UNLOCK_DELAY_P1_S1 + UNLOCK_DURATION_S1 / 2);
    _claim({user: USER_2, season: SEASON_ID_S1, isEarlyClaim: false});
    uint256 s1 = _snapshot();
    _assert(s1, USER_2, SEASON_ID_S1, Field.CLAIMED, CLAIM_HALF_P1_S1_U2);

    // season 2: unlock 0%
    _skipTo(UNLOCK_START_TIME_S2 + UNLOCK_DELAY_P1_S2);
    _claim({user: USER_1, season: SEASON_ID_S2, isEarlyClaim: true});
    uint256 s2 = _snapshot();
    _assert(s2, USER_1, SEASON_ID_S2, Field.CLAIMED, EARLY_CLAIM_START_P1_S2_U1);

    // season 1: unlock 100%
    _skipTo(UNLOCK_START_TIME_S1 + UNLOCK_DELAY_P1_S1 + UNLOCK_DURATION_S1);
    _claim({user: USER_2, season: SEASON_ID_S1, isEarlyClaim: false});
    _claim({user: USER_MSIG, season: SEASON_ID_S1, isEarlyClaim: true});
    uint256 s3 = _snapshot();
    _assert(
      s3, USER_2, SEASON_ID_S1, Field.CLAIMED, _calculateClaimWithLoyalty(USER_2, SEASON_ID_S1)
    );
    _assert(
      s3,
      USER_MSIG,
      SEASON_ID_S1,
      Field.CLAIMED,
      _calculateClaimWithLoyalty(USER_MSIG, SEASON_ID_S1)
    );

    // season 2: unlock 50%
    _skipTo(UNLOCK_START_TIME_S2 + UNLOCK_DELAY_P1_S2 + UNLOCK_DURATION_S2 / 2);
    _claim({user: USER_2, season: SEASON_ID_S2, isEarlyClaim: true});
    uint256 s4 = _snapshot();
    _assert(s4, USER_2, SEASON_ID_S2, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S2_U2);

    // season 2: unlock 100%
    _skipTo(UNLOCK_START_TIME_S2 + UNLOCK_DELAY_P1_S2 + UNLOCK_DURATION_S2);
    _claim({user: USER_MSIG, season: SEASON_ID_S2, isEarlyClaim: true});
    uint256 s5 = _snapshot();
    _assert(
      s5,
      USER_MSIG,
      SEASON_ID_S2,
      Field.CLAIMED,
      _calculateClaimWithLoyalty(USER_MSIG, SEASON_ID_S2)
    );
  }

  // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  // ==================== BULLOAK AUTOGENERATED SEPARATOR ====================
  // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  //    Code below this section could not be automatically moved by bulloak
  // =========================================================================

  function test_ScenarioEarlyClaimHalfwayUnlockPeriodWithPriorEarlyClaimAtSameTime()
    external
    whenSeason1IsSetup
    whenTheUnlockIsInHalfWayForSeason1
    validateSnapshots
  {
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
    _assert(
      s0,
      address(s_claim),
      SEASON_ID_S1,
      Field.TOTAL_LOYALTY,
      MAX_TOKEN_AMOUNT_P1_S1_U1 - EARLY_CLAIM_HALF_P1_S1_U1
    );

    bytes memory revertReason =
      abi.encodeWithSelector(IBUILDClaim.InvalidEarlyClaim.selector, USER_1, SEASON_ID_S1);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true, revertReason: revertReason});
    uint8 s1 = _snapshot();

    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
    _assert(
      s1,
      address(s_claim),
      SEASON_ID_S1,
      Field.TOTAL_LOYALTY,
      MAX_TOKEN_AMOUNT_P1_S1_U1 - EARLY_CLAIM_HALF_P1_S1_U1
    );
  }

  function test_ScenarioEarlyClaimHalfwayUnlockPeriodWithPriorRegularClaimAtSameTime()
    external
    whenSeason1IsSetup
    whenTheUnlockIsInHalfWayForSeason1
    validateSnapshots
  {
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_HALF_P1_S1_U1);
    _assert(s0, address(s_claim), SEASON_ID_S1, Field.TOTAL_LOYALTY, 0);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s1 = _snapshot();

    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
    _assert(
      s1,
      address(s_claim),
      SEASON_ID_S1,
      Field.TOTAL_LOYALTY,
      MAX_TOKEN_AMOUNT_P1_S1_U1 - EARLY_CLAIM_HALF_P1_S1_U1
    );
  }

  function test_ScenarioEarlyClaimHalfwayUnlockPeriodWithPriorEarlyClaimOneTickEarlier()
    external
    whenSeason1IsSetup
    whenTheUnlockIsInHalfWayForSeason1
    validateSnapshots
  {
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s0 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
    _assert(
      s0,
      address(s_claim),
      SEASON_ID_S1,
      Field.TOTAL_LOYALTY,
      MAX_TOKEN_AMOUNT_P1_S1_U1 - EARLY_CLAIM_HALF_P1_S1_U1
    );

    skip(1);
    bytes memory revertReason =
      abi.encodeWithSelector(IBUILDClaim.InvalidEarlyClaim.selector, USER_1, SEASON_ID_S1);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true, revertReason: revertReason});
    uint8 s1 = _snapshot();

    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, EARLY_CLAIM_HALF_P1_S1_U1);
    _assert(
      s1,
      address(s_claim),
      SEASON_ID_S1,
      Field.TOTAL_LOYALTY,
      MAX_TOKEN_AMOUNT_P1_S1_U1 - EARLY_CLAIM_HALF_P1_S1_U1
    );
  }

  function test_ScenarioEarlyClaimHalfwayUnlockPeriodWithPriorRegularClaimOneTickEarlier()
    external
    whenSeason1IsSetup
    whenTheUnlockIsInHalfWayForSeason1
    validateSnapshots
  {
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: false});
    uint8 s0 = _snapshot();

    _assert(s0, USER_1, SEASON_ID_S1, Field.CLAIMED, CLAIM_HALF_P1_S1_U1);
    _assert(s0, address(s_claim), SEASON_ID_S1, Field.TOTAL_LOYALTY, 0);

    skip(1);
    _claim({user: USER_1, season: SEASON_ID_S1, isEarlyClaim: true});
    uint8 s1 = _snapshot();

    // time (requires high precision) = (15 days + 1 sec) / 30 days
    // 10% + 90%*time + (90%)(1-time)(80%*time+10%)
    uint256 t1_claimed = 7750003124998928323;
    uint256 t1_loyaltyContribution = MAX_TOKEN_AMOUNT_P1_S1_U1 - t1_claimed;

    _assert(s1, USER_1, SEASON_ID_S1, Field.CLAIMED, t1_claimed);
    _assert(s1, address(s_claim), SEASON_ID_S1, Field.TOTAL_LOYALTY, t1_loyaltyContribution);
  }
}
