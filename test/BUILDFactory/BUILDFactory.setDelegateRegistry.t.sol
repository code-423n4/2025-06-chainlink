// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";
import {IDelegateRegistry} from "@delegatexyz/delegate-registry/v2.0/src/IDelegateRegistry.sol";

contract BUILDFactorySetDelegateRegistryTest is BaseTest {
  function test_RevertWhen_TheCallerDoesNotHaveTheDEFAULT_ADMIN_ROLE() external {
    _changePrank(NOBODY);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        NOBODY,
        s_factory.DEFAULT_ADMIN_ROLE()
      )
    );
    s_factory.setDelegateRegistry(IDelegateRegistry(address(1)));
  }

  modifier whenTheCallerHasTheDEFAULT_ADMIN_ROLE() {
    _changePrank(ADMIN);
    _;
  }

  function test_RevertWhen_theDelegateRegistryIsZeroAddress()
    external
    whenTheCallerHasTheDEFAULT_ADMIN_ROLE
  {
    // it should revert
    vm.expectRevert(IBUILDFactory.InvalidZeroAddress.selector);
    s_factory.setDelegateRegistry(IDelegateRegistry(address(0)));
  }

  function test_WhenTheDelegateRegistryIsTheSameAsTheCurrent()
    external
    whenTheCallerHasTheDEFAULT_ADMIN_ROLE
  {
    IDelegateRegistry currentDelegateRegistry = s_factory.getDelegateRegistry();
    vm.recordLogs();
    s_factory.setDelegateRegistry(currentDelegateRegistry);
    // it should not emit a DelegateRegistryUpdated event
    assertEq(vm.getRecordedLogs().length, 0);
    // it should not update the value
    assertEq(address(s_factory.getDelegateRegistry()), address(currentDelegateRegistry));
  }

  function test_WhenTheDelegateRegistryIsUpdated() external whenTheCallerHasTheDEFAULT_ADMIN_ROLE {
    IDelegateRegistry newDelegateRegistry = IDelegateRegistry(address(1));
    // it should emit a DelegateRegistryUpdated event
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.DelegateRegistryUpdated(address(newDelegateRegistry));
    s_factory.setDelegateRegistry(newDelegateRegistry);
    // it should set the delegate registry
    assertEq(address(s_factory.getDelegateRegistry()), address(newDelegateRegistry));
  }
}
