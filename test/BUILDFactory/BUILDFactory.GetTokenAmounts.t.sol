// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

contract BUILDFactoryGetTokenAmountsTest is BaseTest {
  function test_WhenNoDepositsHaveBeenMade()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
  {
    // it should return zeros
    IBUILDFactory.TokenAmounts memory amounts = s_factory.getTokenAmounts(address(s_token));
    assertEq(amounts.totalDeposited, 0);
    assertEq(amounts.totalWithdrawn, 0);
    assertEq(amounts.totalAllocatedToAllSeasons, 0);
    assertEq(amounts.totalRefunded, 0);
  }

  function test_WhenADepositHasBeenMade()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
  {
    uint256 deposit = TOKEN_AMOUNT_P1_S1 + TOKEN_AMOUNT_P1_S2;
    // it should return the increased total deposited amount
    IBUILDFactory.TokenAmounts memory amounts = s_factory.getTokenAmounts(address(s_token));
    assertEq(amounts.totalDeposited, deposit);
    assertEq(amounts.totalWithdrawn, 0);
    assertEq(amounts.totalAllocatedToAllSeasons, 0);
    assertEq(amounts.totalRefunded, 0);
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

    // it should return the increased total withdrawn amount
    IBUILDFactory.TokenAmounts memory amounts = s_factory.getTokenAmounts(address(s_token));
    assertEq(amounts.totalDeposited, deposit); // same
    assertEq(amounts.totalWithdrawn, deposit); // increased
    assertEq(amounts.totalAllocatedToAllSeasons, 0);
    assertEq(amounts.totalRefunded, 0);
  }

  function test_WhenTokensAreAllocatedToASeason()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
  {
    uint256 deposit = TOKEN_AMOUNT_P1_S1 + TOKEN_AMOUNT_P1_S2;
    // it should return the increased total allocated to seasons amount
    IBUILDFactory.TokenAmounts memory amounts = s_factory.getTokenAmounts(address(s_token));
    assertEq(amounts.totalDeposited, deposit);
    assertEq(amounts.totalWithdrawn, 0);
    assertEq(amounts.totalAllocatedToAllSeasons, TOKEN_AMOUNT_P1_S1); // increased
    assertEq(amounts.totalRefunded, 0);
  }

  function test_WhenARefundHasStarted()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenProjectSeasonIsRefunding
  {
    uint256 deposit = TOKEN_AMOUNT_P1_S1 + TOKEN_AMOUNT_P1_S2;
    // it should return the increased total refunded amount
    IBUILDFactory.TokenAmounts memory amounts = s_factory.getTokenAmounts(address(s_token));
    assertEq(amounts.totalDeposited, deposit);
    assertEq(amounts.totalWithdrawn, 0);
    assertEq(amounts.totalAllocatedToAllSeasons, TOKEN_AMOUNT_P1_S1);
    assertEq(amounts.totalRefunded, TOKEN_AMOUNT_P1_S1); // increased
  }
}
