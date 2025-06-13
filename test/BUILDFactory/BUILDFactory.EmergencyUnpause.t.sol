// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {BaseTest} from "../BaseTest.t.sol";

contract BUILDFactoryEmergencyUnpauseTest is BaseTest {
  function test_RevertWhen_TheCallerDoesNotHaveThePAUSER_ROLE() external whenFactoryPaused(PAUSER) {
    _changePrank(NOBODY);
    assertEq(s_factory.hasRole(s_factory.PAUSER_ROLE(), NOBODY), false);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector, NOBODY, s_factory.PAUSER_ROLE()
      )
    );
    s_factory.emergencyUnpause();
  }

  function test_RevertWhen_NotPaused() external whenPauserHasFactoryPauserRole(PAUSER) {
    _changePrank(PAUSER);
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(Pausable.ExpectedPause.selector));
    s_factory.emergencyUnpause();
  }

  function test_WhenPausedAndTheCallerHasThePAUSER_ROLE()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenProject2AddedAndClaimDeployed
    whenClaimPaused(PAUSER, address(s_token))
    whenFactoryPaused(PAUSER)
  {
    // it should unpause the contract
    vm.expectEmit(address(s_factory));
    emit Pausable.Unpaused(PAUSER);
    s_factory.emergencyUnpause();
    assertEq(s_factory.paused(), false);

    // it should not unpause claim contracts individually paused
    assertEq(s_factory.isClaimContractPaused(address(s_token)), true);

    // it should unpause all claim contracts otherwise
    assertEq(s_factory.isClaimContractPaused(address(s_token_2)), false);
  }
}
