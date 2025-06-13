// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

/// @notice Requirements
/// [BUS1.3.4.1.1](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=6934fa70-70bb-4cab-b426-90b21e960b48)
contract BUILDFactoryUnlockConfigMaxValuesTest is BaseTest {
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
    s_factory.setUnlockConfigMaxValues(
      IBUILDFactory.UnlockMaxConfigs({
        maxUnlockDuration: MAX_UNLOCK_DURATION,
        maxUnlockDelay: MAX_UNLOCK_DELAY
      })
    );
  }

  modifier whenTheCallerHasTheDEFAULT_ADMIN_ROLE() {
    _changePrank(ADMIN);
    _;
  }

  function test_RevertWhen_TheMaxUnlockDurationIsZero()
    external
    whenTheCallerHasTheDEFAULT_ADMIN_ROLE
  {
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.InvalidZeroMaxUnlockDuration.selector));
    s_factory.setUnlockConfigMaxValues(
      IBUILDFactory.UnlockMaxConfigs({maxUnlockDuration: 0, maxUnlockDelay: MAX_UNLOCK_DELAY})
    );
  }

  function test_RevertWhen_TheMaxUnlockDelayIsZero() external whenTheCallerHasTheDEFAULT_ADMIN_ROLE {
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.InvalidZeroMaxUnlockDelay.selector));
    s_factory.setUnlockConfigMaxValues(
      IBUILDFactory.UnlockMaxConfigs({maxUnlockDuration: MAX_UNLOCK_DURATION, maxUnlockDelay: 0})
    );
  }

  function test_WhenTheMaxUnlockDurationAndDelayAreTheSameAsTheCurrentValues()
    external
    whenTheCallerHasTheDEFAULT_ADMIN_ROLE
  {
    // it should not update the values
    s_factory.setUnlockConfigMaxValues(
      IBUILDFactory.UnlockMaxConfigs({
        maxUnlockDuration: MAX_UNLOCK_DURATION,
        maxUnlockDelay: MAX_UNLOCK_DELAY
      })
    );
    IBUILDFactory.UnlockMaxConfigs memory config = s_factory.getUnlockConfigMaxValues();
    assertEq(config.maxUnlockDuration, MAX_UNLOCK_DURATION);
    assertEq(config.maxUnlockDelay, MAX_UNLOCK_DELAY);
  }

  function test_WhenTheMaxUnlockDurationIsTheSameAsTheCurrentValue()
    external
    whenTheCallerHasTheDEFAULT_ADMIN_ROLE
  {
    // it should only set the delay
    // it should emit a MaxUnlockDelayUpdated event
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.MaxUnlockDelayUpdated(MAX_UNLOCK_DELAY + 1);
    s_factory.setUnlockConfigMaxValues(
      IBUILDFactory.UnlockMaxConfigs({
        maxUnlockDuration: MAX_UNLOCK_DURATION,
        maxUnlockDelay: MAX_UNLOCK_DELAY + 1
      })
    );
    IBUILDFactory.UnlockMaxConfigs memory config = s_factory.getUnlockConfigMaxValues();
    assertEq(config.maxUnlockDuration, MAX_UNLOCK_DURATION);
    assertEq(config.maxUnlockDelay, MAX_UNLOCK_DELAY + 1);
  }

  function test_WhenTheMaxUnlockDelayIsTheSameAsTheCurrentValue()
    external
    whenTheCallerHasTheDEFAULT_ADMIN_ROLE
  {
    // it should only set the duration
    // it should emit a MaxUnlockDurationUpdated event
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.MaxUnlockDurationUpdated(MAX_UNLOCK_DURATION + 1);
    s_factory.setUnlockConfigMaxValues(
      IBUILDFactory.UnlockMaxConfigs({
        maxUnlockDuration: MAX_UNLOCK_DURATION + 1,
        maxUnlockDelay: MAX_UNLOCK_DELAY
      })
    );
    IBUILDFactory.UnlockMaxConfigs memory config = s_factory.getUnlockConfigMaxValues();
    assertEq(config.maxUnlockDuration, MAX_UNLOCK_DURATION + 1);
    assertEq(config.maxUnlockDelay, MAX_UNLOCK_DELAY);
  }

  function test_WhenTheMaxUnlockDurationAndDelayAreDifferentFromTheCurrentValues()
    external
    whenTheCallerHasTheDEFAULT_ADMIN_ROLE
  {
    // it should update the values
    // it should emit a MaxUnlockDurationUpdated event
    // it should emit a MaxUnlockDelayUpdated event
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.MaxUnlockDurationUpdated(MAX_UNLOCK_DURATION + 1);
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.MaxUnlockDelayUpdated(MAX_UNLOCK_DELAY + 1);
    s_factory.setUnlockConfigMaxValues(
      IBUILDFactory.UnlockMaxConfigs({
        maxUnlockDuration: MAX_UNLOCK_DURATION + 1,
        maxUnlockDelay: MAX_UNLOCK_DELAY + 1
      })
    );
    IBUILDFactory.UnlockMaxConfigs memory config = s_factory.getUnlockConfigMaxValues();
    assertEq(config.maxUnlockDuration, MAX_UNLOCK_DURATION + 1);
    assertEq(config.maxUnlockDelay, MAX_UNLOCK_DELAY + 1);
  }
}
