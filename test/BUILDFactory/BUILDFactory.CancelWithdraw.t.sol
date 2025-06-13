// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

/// @notice Requirements
/// @notice Requirements
/// [BUS10.1](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=320a0b93-347d-42a1-a3b2-54f5254b1f70&fieldId=28d1c574-a71d-5e3e-babb-d23bb4454358)
/// [BUS10.2](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=2e0a11f5-29df-402e-bad3-4b225c0a251d&fieldId=28d1c574-a71d-5e3e-babb-d23bb4454358)
contract BUILDFactoryCancelWithdrawTest is BaseTest {
  function test_RevertWhen_TheCallerIsNotFactoryAdmin()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
  {
    _changePrank(NOBODY);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        NOBODY,
        s_factory.DEFAULT_ADMIN_ROLE()
      )
    );
    s_factory.cancelWithdraw(address(s_token));
  }

  modifier whenTheCallerIsFactoryAdmin() {
    _changePrank(ADMIN);
    _;
  }

  function test_RevertWhen_NoWithdrawalIsScheduled()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsFactoryAdmin
  {
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(IBUILDFactory.WithdrawalDoesNotExist.selector, address(s_token))
    );
    s_factory.cancelWithdraw(address(s_token));
  }

  function test_WhenWithdrawalIsScheduled()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenTheCallerIsFactoryAdmin
  {
    s_factory.scheduleWithdraw(address(s_token), PROJECT_ADMIN, 10);
    // it should cancel the withdrawal

    s_factory.cancelWithdraw(address(s_token));
    IBUILDFactory.Withdrawal memory withdrawal = s_factory.getScheduledWithdrawal(address(s_token));
    assertEq(withdrawal.amount, 0);
    assertEq(withdrawal.recipient, address(0));
  }
}
