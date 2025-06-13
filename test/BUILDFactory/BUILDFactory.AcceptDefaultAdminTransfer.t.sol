// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IAccessControlDefaultAdminRules} from
  "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";
import {BaseTest} from "../BaseTest.t.sol";

contract BUILDFactoryAcceptDefaultAdminTransferTest is BaseTest {
  function test_RevertWhen_TheCallerIsNotTheCurrentPendingAdmin() external {
    _changePrank(ADMIN);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControlDefaultAdminRules.AccessControlInvalidDefaultAdmin.selector, ADMIN
      )
    );
    s_factory.acceptDefaultAdminTransfer();
  }

  function test_WhenThereIsNoPendingTransfer() external {
    _changePrank(NOBODY);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControlDefaultAdminRules.AccessControlInvalidDefaultAdmin.selector, NOBODY
      )
    );
    s_factory.acceptDefaultAdminTransfer();
  }

  function test_WhenTheDelayHasNotPassed() external whenThereIsPendingAdminTransfer {
    _changePrank(NOBODY);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminDelay.selector,
        block.timestamp
      )
    );
    s_factory.acceptDefaultAdminTransfer();
  }

  function test_WhenTheDelayHasPassed() external whenThereIsPendingAdminTransfer {
    _changePrank(NOBODY);
    skip(1);
    // it should update the default admin
    // it should reset the pending transfer
    // it should emit RoleGranted event
    vm.expectEmit(address(s_factory));
    emit IAccessControl.RoleGranted(s_factory.DEFAULT_ADMIN_ROLE(), NOBODY, NOBODY);
    s_factory.acceptDefaultAdminTransfer();
    assertEq(s_factory.hasRole(s_factory.DEFAULT_ADMIN_ROLE(), NOBODY), true);
    assertEq(s_factory.defaultAdmin(), NOBODY);
    (address pendingAdmin, uint256 schedule) = s_factory.pendingDefaultAdmin();
    assertEq(pendingAdmin, address(0));
    assertEq(schedule, 0);
  }
}
