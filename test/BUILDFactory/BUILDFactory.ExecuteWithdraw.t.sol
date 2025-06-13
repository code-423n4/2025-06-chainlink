// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

contract BUILDFactoryExecuteWithdrawTest is BaseTest {
  function test_RevertWhen_TheCallerIsNotTheRegisteredClaimContract() external {
    _changePrank(NOBODY);
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.Unauthorized.selector));
    s_factory.executeWithdraw(address(s_token));
  }

  function test_RevertWhen_ThereIsNoScheduledWithdrawal() external whenProjectAddedAndClaimDeployed {
    _changePrank(address(s_claim));
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(IBUILDFactory.WithdrawalDoesNotExist.selector, address(s_token))
    );
    s_factory.executeWithdraw(address(s_token));
  }

  function test_When_ThereIsAScheduledWithdrawal()
    external
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
  {
    _changePrank(ADMIN);
    uint256 withdrawAmount = 100;
    s_factory.scheduleWithdraw(address(s_token), PROJECT_ADMIN, withdrawAmount);

    _changePrank(address(s_claim));
    // it should update the total withdrawn
    // it should reset the scheduled withdrawal
    // it should return the scheduled withdrawal and the updated total withdrawn
    (IBUILDFactory.Withdrawal memory executedWithdrawal, uint256 updatedTotalWithdrawn) =
      s_factory.executeWithdraw(address(s_token));
    assertEq(executedWithdrawal.amount, withdrawAmount);
    assertEq(executedWithdrawal.recipient, PROJECT_ADMIN);
    assertEq(updatedTotalWithdrawn, withdrawAmount);
    IBUILDFactory.TokenAmounts memory tokenAmounts = s_factory.getTokenAmounts(address(s_token));
    assertEq(tokenAmounts.totalWithdrawn, withdrawAmount);
    // it should return default values
    IBUILDFactory.Withdrawal memory scheduledWithdrawal =
      s_factory.getScheduledWithdrawal(address(s_token));
    assertEq(scheduledWithdrawal.amount, 0);
    assertEq(scheduledWithdrawal.recipient, address(0));
  }
}
