// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {BaseTest} from "../BaseTest.t.sol";

/// @notice Requirements
/// [BUS14](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=188eab1d-bfa0-412a-aa2f-009c0c0ef34d)
contract BUILDFactoryEmergencyPauseTest is BaseTest {
  function test_RevertWhen_TheCallerDoesNotHaveThePAUSER_ROLE() external {
    _changePrank(NOBODY);
    assertEq(s_factory.hasRole(s_factory.PAUSER_ROLE(), NOBODY), false);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector, NOBODY, s_factory.PAUSER_ROLE()
      )
    );
    s_factory.emergencyPause();
  }

  function test_RevertWhen_AlreadyPaused() external whenPauserHasFactoryPauserRole(PAUSER) {
    _changePrank(PAUSER);
    s_factory.emergencyPause();
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
    s_factory.emergencyPause();
  }

  function test_WhenTheCallerHasThePAUSER_ROLE()
    external
    whenPauserHasFactoryPauserRole(PAUSER)
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenProject2AddedAndClaimDeployed
  {
    _changePrank(PAUSER);
    assertEq(s_factory.isClaimContractPaused(address(s_token)), false);
    assertEq(s_factory.isClaimContractPaused(address(s_token_2)), false);

    // it should pause the contract
    vm.expectEmit(address(s_factory));
    emit Pausable.Paused(PAUSER);
    s_factory.emergencyPause();
    assertEq(s_factory.paused(), true);
    // it should pause all claim contracts
    assertEq(s_factory.isClaimContractPaused(address(s_token)), true);
    assertEq(s_factory.isClaimContractPaused(address(s_token_2)), true);
  }
}
