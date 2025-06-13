// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IAccessControlDefaultAdminRules} from
  "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";
import {BaseTest} from "../BaseTest.t.sol";

contract BUILDFactoryCancelDefaultAdminTransferTest is BaseTest {
  function test_RevertWhen_TheCallerIsNotTheCurrentDefaultAdmin() external {
    _changePrank(NOBODY);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        NOBODY,
        s_factory.DEFAULT_ADMIN_ROLE()
      )
    );
    s_factory.cancelDefaultAdminTransfer();
  }

  function test_WhenThereIsNoPendingTransfer() external {
    _changePrank(ADMIN);
    (address pendingAdminBefore, uint256 scheduleBefore) = s_factory.pendingDefaultAdmin();
    assertEq(pendingAdminBefore, address(0));
    assertEq(scheduleBefore, 0);

    // it should not set the pending transfer
    s_factory.cancelDefaultAdminTransfer();
    (address pendingAdminAfter, uint256 scheduleAfter) = s_factory.pendingDefaultAdmin();
    assertEq(pendingAdminAfter, pendingAdminBefore);
    assertEq(scheduleAfter, scheduleBefore);
  }

  function test_WhenThereIsAPendingTransfer() external whenThereIsPendingAdminTransfer {
    (address pendingAdminBefore, uint256 scheduleBefore) = s_factory.pendingDefaultAdmin();
    assertEq(pendingAdminBefore, NOBODY);
    assertEq(scheduleBefore, block.timestamp);
    skip(1);

    _changePrank(ADMIN);

    // it should reset the pending transfer
    // it should emit DefaultAdminTransferCanceled event
    vm.expectEmit(address(s_factory));
    emit IAccessControlDefaultAdminRules.DefaultAdminTransferCanceled();
    s_factory.cancelDefaultAdminTransfer();
    (address pendingAdminAfter, uint256 scheduleAfter) = s_factory.pendingDefaultAdmin();
    assertEq(pendingAdminAfter, address(0));
    assertEq(scheduleAfter, 0);
  }
}
