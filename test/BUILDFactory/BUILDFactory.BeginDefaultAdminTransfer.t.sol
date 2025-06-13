// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IAccessControlDefaultAdminRules} from
  "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";
import {BaseTest} from "../BaseTest.t.sol";

contract BUILDFactoryBeginDefaultAdminTransferTest is BaseTest {
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
    s_factory.beginDefaultAdminTransfer(NOBODY);
  }

  function test_WhenThereIsAPendingTransfer() external whenThereIsPendingAdminTransfer {
    (address pendingAdminBefore, uint256 scheduleBefore) = s_factory.pendingDefaultAdmin();
    assertEq(pendingAdminBefore, NOBODY);
    assertEq(scheduleBefore, block.timestamp);
    skip(1);

    _changePrank(ADMIN);

    // it should update the pending transfer
    // it should emit DefaultAdminTransferCanceled event
    vm.expectEmit(address(s_factory));
    emit IAccessControlDefaultAdminRules.DefaultAdminTransferCanceled();
    s_factory.beginDefaultAdminTransfer(PAUSER);
    (address pendingAdminAfter, uint256 scheduleAfter) = s_factory.pendingDefaultAdmin();
    assertEq(pendingAdminAfter, PAUSER);
    assertEq(scheduleAfter, scheduleBefore + 1);
  }

  function test_WhenThereIsNoPendingTransfer() external {
    _changePrank(ADMIN);
    (address pendingAdminBefore, uint256 scheduleBefore) = s_factory.pendingDefaultAdmin();
    assertEq(pendingAdminBefore, address(0));
    assertEq(scheduleBefore, 0);

    // it should set the pending transfer
    s_factory.beginDefaultAdminTransfer(NOBODY);
    (address pendingAdminAfter, uint256 scheduleAfter) = s_factory.pendingDefaultAdmin();
    assertEq(pendingAdminAfter, NOBODY);
    assertEq(scheduleAfter, block.timestamp);
  }
}
