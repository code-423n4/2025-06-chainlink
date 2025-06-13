// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDClaim} from "../../src/interfaces/IBUILDClaim.sol";

contract BUILDClaimGetUserStateTest is BaseTest {
  function test_WhenTheProvidedSeasonDoesNotExist() external whenProjectAddedAndClaimDeployed {
    // it should return zero claimed, false hasEarlyClaimed
    IBUILDClaim.UserState memory state =
      s_claim.getUserState(_singleUserState(USER_1, SEASON_ID_S1))[0];
    assertEq(state.claimed, 0);
    assertEq(state.hasEarlyClaimed, false);
  }

  function test_WhenTheUserHasNotClaimed()
    external
    whenProjectAddedAndClaimDeployed
    whenASeasonConfigIsSetForTheSeason
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
  {
    // it should return zero claimed, false hasEarlyClaimed
    IBUILDClaim.UserState memory state =
      s_claim.getUserState(_singleUserState(USER_1, SEASON_ID_S1))[0];
    assertEq(state.claimed, 0);
    assertEq(state.hasEarlyClaimed, false);
  }

  function test_WhenTheUserHasClaimed()
    external
    whenProjectAddedAndClaimDeployed
    whenASeasonConfigIsSetForTheSeason
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
    whenTheUserClaimedTheUnlockedTokens
  {
    // it should return the claimed amount, false hasEarlyClaimed
    // base tokens = 10 tokens * 10% = 1 token
    // unlocked bonus tokens = (10 - 1) tokens * (15 days / 30 days) = 4.5 tokens
    uint256 expectedClaimedAmount = 5.5 ether;
    IBUILDClaim.UserState memory state =
      s_claim.getUserState(_singleUserState(USER_1, SEASON_ID_S1))[0];
    assertEq(state.claimed, expectedClaimedAmount);
    assertEq(state.hasEarlyClaimed, false);
  }

  function test_WhenTheUserHasEarlyClaimed()
    external
    whenProjectAddedAndClaimDeployed
    whenASeasonConfigIsSetForTheSeason
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
    whenTheUserEarlyClaimed
  {
    // it should return the early claimed amount, true hasEarlyClaimed
    // Base tokens = 10 tokens * 10% = 1 token
    // Unlocked bonus tokens = (10 - 1) tokens * (15 days / 30 days) = 4.5 tokens
    // Early claimed bonus tokens
    //   = (10 - 1 - 4.5) tokens * (10% + (90% - 10%) * (15 days / 30 days))
    //   = 4.5 tokens * 50% = 2.25 tokens
    // Total = 1 + 4.5 + 2.25 = 7.75 tokens
    uint256 expectedClaimedAmount = 7.75 ether;
    IBUILDClaim.UserState memory state =
      s_claim.getUserState(_singleUserState(USER_1, SEASON_ID_S1))[0];
    assertEq(state.claimed, expectedClaimedAmount);
    assertEq(state.hasEarlyClaimed, true);
  }
}
