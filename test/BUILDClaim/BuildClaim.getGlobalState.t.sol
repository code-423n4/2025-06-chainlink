// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDClaim} from "../../src/interfaces/IBUILDClaim.sol";

contract BUILDClaimGetGlobalStateTest is BaseTest {
  function test_WhenTheProvidedSeasonDoesNotExist() external whenProjectAddedAndClaimDeployed {
    // it should return zero
    assertEq(s_claim.getGlobalState(SEASON_ID_S1).totalClaimed, 0);
  }

  function test_WhenNoUserHasClaimed()
    external
    whenProjectAddedAndClaimDeployed
    whenASeasonConfigIsSetForTheSeason
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
  {
    // it should return zero
    assertEq(s_claim.getGlobalState(SEASON_ID_S1).totalClaimed, 0);
  }

  function test_WhenAUserHasClaimed()
    external
    whenProjectAddedAndClaimDeployed
    whenASeasonConfigIsSetForTheSeason
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
    whenTheUserClaimedTheUnlockedTokens
  {
    // it should return the claimed amount
    // base tokens = 10 tokens * 10% = 1 token
    // unlocked bonus tokens = (10 - 1) tokens * (15 days / 30 days) = 4.5 tokens
    uint256 expectedClaimedAmount = 5.5 ether;
    assertEq(s_claim.getGlobalState(SEASON_ID_S1).totalClaimed, expectedClaimedAmount);
  }

  function test_WhenMultipleUsersHaveClaimed()
    external
    whenProjectAddedAndClaimDeployed
    whenASeasonConfigIsSetForTheSeason
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
    whenTheUserClaimedTheUnlockedTokens
  {
    _changePrank(USER_2);
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U2,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U2,
      salt: SALT_U2,
      isEarlyClaim: false
    });
    s_claim.claim(USER_2, params);
    // it should return the sum of claimed amounts
    // user 1:
    // base tokens = 10 tokens * 10% = 1 token
    // unlocked bonus tokens = (10 - 1) tokens * (15 days / 30 days) = 4.5 tokens
    // user 2:
    // base tokens = 90 tokens * 10% = 9 token
    // unlocked bonus tokens = (90 - 9) tokens * (15 days / 30 days) = 40.5 tokens
    // total:
    // 1 + 4.5 + 9 + 40.5 = 55
    uint256 expectedClaimedAmount = 55 ether;
    assertEq(s_claim.getGlobalState(SEASON_ID_S1).totalClaimed, expectedClaimedAmount);
  }
}
