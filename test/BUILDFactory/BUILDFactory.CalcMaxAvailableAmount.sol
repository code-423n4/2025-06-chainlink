// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../BaseTest.t.sol";

contract BUILDFactoryCalcMaxAvailableAmountTest is BaseTest {
  function test_WhenNoDepositsHaveBeenMade()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
  {
    // it should return zero
    assertEq(s_factory.calcMaxAvailableAmount(address(s_token)), 0);
  }

  function test_WhenADepositHasBeenMade()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
  {
    uint256 deposit = TOKEN_AMOUNT_P1_S1 + TOKEN_AMOUNT_P1_S2;
    // it should return the total deposited amount as max available
    assertEq(s_factory.calcMaxAvailableAmount(address(s_token)), deposit);
  }

  function test_WhenAllTokensAreWithdrawn()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
  {
    _changePrank(ADMIN);
    uint256 deposit = TOKEN_AMOUNT_P1_S1 + TOKEN_AMOUNT_P1_S2;
    s_factory.scheduleWithdraw(address(s_token), PROJECT_ADMIN, deposit);
    _changePrank(PROJECT_ADMIN);
    s_claim.withdraw();

    // it should return zero as max available
    assertEq(s_factory.calcMaxAvailableAmount(address(s_token)), 0);
  }

  function test_WhenTokensAreAllocatedToASeason()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
  {
    uint256 deposit = TOKEN_AMOUNT_P1_S1 + TOKEN_AMOUNT_P1_S2;
    // it should return the correct max available
    assertEq(s_factory.calcMaxAvailableAmount(address(s_token)), deposit - TOKEN_AMOUNT_P1_S1);
  }

  function test_WhenARefundHasStarted()
    external
    whenProjectAdded
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenProjectSeasonIsRefunding
  {
    uint256 deposit = TOKEN_AMOUNT_P1_S1 + TOKEN_AMOUNT_P1_S2;
    // it should return the correct max available
    // no one claimed so all allocated tokens are refunded
    assertEq(s_factory.calcMaxAvailableAmount(address(s_token)), deposit);
  }

  function test_WhenARefundHasStartedAfterSomeClaimed()
    external
    whenProjectAdded
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockEndedForProject1Season1
    whenTheUserClaimedTheUnlockedTokens
    whenProjectSeasonIsRefunding
  {
    uint256 deposit = TOKEN_AMOUNT_P1_S1 + TOKEN_AMOUNT_P1_S2;
    // it should return the correct max available
    // user 1 claimed so only the remaining tokens are refunded
    assertEq(
      s_factory.calcMaxAvailableAmount(address(s_token)), deposit - MAX_TOKEN_AMOUNT_P1_S1_U1
    );
  }

  function test_WhenSomeTokensAreWithdrawn()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenProjectSeasonIsRefunding
  {
    uint256 deposit = TOKEN_AMOUNT_P1_S1 + TOKEN_AMOUNT_P1_S2;
    assertEq(s_factory.calcMaxAvailableAmount(address(s_token)), deposit);

    _changePrank(ADMIN);
    uint256 withdrawAmount = 100;
    s_factory.scheduleWithdraw(address(s_token), PROJECT_ADMIN, withdrawAmount);

    _changePrank(PROJECT_ADMIN);
    s_claim.withdraw();

    // it should return the correct max available
    assertEq(s_factory.calcMaxAvailableAmount(address(s_token)), deposit - withdrawAmount);
  }
}
