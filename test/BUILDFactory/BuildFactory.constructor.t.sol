// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControlDefaultAdminRules} from
  "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {BUILDFactory} from "./../../src/BUILDFactory.sol";
import {IBUILDFactory} from "./../../src/interfaces/IBUILDFactory.sol";
import {IDelegateRegistry} from "@delegatexyz/delegate-registry/v2.0/src/IDelegateRegistry.sol";

contract BUILDFactoryConstructorTest is BaseTest {
  function test_RevertWhen_TheAdminIsSetToTheZeroAddress() external {
    BUILDFactory.ConstructorParams memory params = BUILDFactory.ConstructorParams({
      admin: address(0),
      maxUnlockDuration: MAX_UNLOCK_DURATION,
      maxUnlockDelay: MAX_UNLOCK_DELAY,
      delegateRegistry: IDelegateRegistry(s_delegateRegistry)
    });
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControlDefaultAdminRules.AccessControlInvalidDefaultAdmin.selector, address(0)
      )
    );
    new BUILDFactory(params);
  }

  function test_RevertWhen_TheDelegateRegistryIsSetToTheZeroAddress() external {
    BUILDFactory.ConstructorParams memory params = BUILDFactory.ConstructorParams({
      admin: address(1),
      maxUnlockDuration: MAX_UNLOCK_DURATION,
      maxUnlockDelay: MAX_UNLOCK_DELAY,
      delegateRegistry: IDelegateRegistry(address(0))
    });
    // it should revert
    vm.expectRevert(IBUILDFactory.InvalidZeroAddress.selector);
    new BUILDFactory(params);
  }

  function test_WhenTheAdminIsSetToANonZeroAddress() external {
    BUILDFactory.ConstructorParams memory params = BUILDFactory.ConstructorParams({
      admin: address(1),
      maxUnlockDuration: MAX_UNLOCK_DURATION,
      maxUnlockDelay: MAX_UNLOCK_DELAY,
      delegateRegistry: IDelegateRegistry(s_delegateRegistry)
    });
    BUILDFactory f = new BUILDFactory(params);
    // it should grant the admin role to the admin address
    assertEq(f.hasRole(f.DEFAULT_ADMIN_ROLE(), params.admin), true);
    assertEq(f.defaultAdmin(), params.admin);
    assertEq(f.defaultAdminDelay(), 0);
  }
}
