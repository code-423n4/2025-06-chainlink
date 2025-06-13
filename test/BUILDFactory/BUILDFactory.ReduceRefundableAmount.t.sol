// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

contract BUILDFactoryReduceRefundableAmountTest is BaseTest {
  function test_WhenTheCallerIsNotTheRegisteredClaim()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
  {
    _changePrank(NOBODY);
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.Unauthorized.selector));
    s_factory.reduceRefundableAmount(address(s_token), SEASON_ID_S1, 100);
  }

  function test_WhenAmountProvidedIsInvalid()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
  {
    _changePrank(address(s_claim));
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.InvalidAmount.selector));
    s_factory.reduceRefundableAmount(address(s_token), SEASON_ID_S1, TOKEN_AMOUNT_P1_S1 + 1);
  }

  function test_WhenAValidAmountIsProvided()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
  {
    _changePrank(address(s_claim));
    // it should update the refundable amount
    uint256 notRefundableAmount = 100;
    s_factory.reduceRefundableAmount(address(s_token), SEASON_ID_S1, notRefundableAmount);
    assertEq(
      s_factory.getRefundableAmount(address(s_token), SEASON_ID_S1),
      TOKEN_AMOUNT_P1_S1 - notRefundableAmount
    );
  }
}
