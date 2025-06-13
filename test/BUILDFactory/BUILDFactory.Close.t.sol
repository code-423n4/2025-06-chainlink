// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Closable} from "./../../src/Closable.sol";
import {BaseTest} from "../BaseTest.t.sol";

contract BUILDFactoryCloseTest is BaseTest {
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
    s_factory.close();
  }

  function test_RevertWhen_AlreadyClosed() external {
    _changePrank(ADMIN);
    s_factory.close();
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(Closable.AlreadyClosed.selector));
    s_factory.close();
  }

  function test_WhenOpenAndTheCallerHasTheDEFAULT_ADMIN_ROLE() external {
    _changePrank(ADMIN);
    vm.expectEmit(address(s_factory));
    emit Closable.Closed();
    s_factory.close();
    // it should close the factory
    assertEq(s_factory.isOpen(), false);
  }
}
