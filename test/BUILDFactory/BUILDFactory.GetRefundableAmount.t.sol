// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../BaseTest.t.sol";

contract BUILDFactoryGetRefundableAmountTest is BaseTest {
  function test_WhenNoSeasonHasBeenConfigured()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
  {
    // it should return zeros
    assertEq(s_factory.getRefundableAmount(address(s_token), SEASON_ID_S1), 0);
  }

  function test_WhenASeasonHasBeenConfigured()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
  {
    // it should return the amount allocated to the season
    assertEq(s_factory.getRefundableAmount(address(s_token), SEASON_ID_S1), TOKEN_AMOUNT_P1_S1);
  }

  function test_WhenAUserClaims()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockEndedForProject1Season1
    whenTheUserClaimedTheUnlockedTokens
  {
    // it should return a decreased amount
    assertEq(
      s_factory.getRefundableAmount(address(s_token), SEASON_ID_S1),
      TOKEN_AMOUNT_P1_S1 - MAX_TOKEN_AMOUNT_P1_S1_U1
    );
  }
}
