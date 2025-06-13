// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

/// @notice Requirements
/// [BUS14.1](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=3da2c635-25ef-478e-b6b7-c67b8bd80a56)
contract BUILDFactoryPauseClaimContractTest is BaseTest {
  function test_RevertWhen_TheCallerDoesNotHaveThePAUSER_ROLE()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
  {
    _changePrank(NOBODY);
    assertEq(s_factory.hasRole(s_factory.PAUSER_ROLE(), NOBODY), false);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector, NOBODY, s_factory.PAUSER_ROLE()
      )
    );
    s_factory.pauseClaimContract(address(s_token));
  }

  function test_RevertWhen_TheClaimContractDoesNotExist()
    external
    whenASeasonConfigIsSetForTheSeason
    whenPauserHasFactoryPauserRole(PAUSER)
  {
    _changePrank(PAUSER);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(IBUILDFactory.ProjectDoesNotExist.selector, address(s_token))
    );
    s_factory.pauseClaimContract(address(s_token));
  }

  function test_RevertWhen_AlreadyPaused()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenPauserHasFactoryPauserRole(PAUSER)
  {
    _changePrank(PAUSER);
    s_factory.pauseClaimContract(address(s_token));
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
    s_factory.pauseClaimContract(address(s_token));
  }

  function test_WhenTheCallerHasThePAUSER_ROLE()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenPauserHasFactoryPauserRole(PAUSER)
  {
    _changePrank(PAUSER);
    // it should pause the contract
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.ClaimPaused(address(s_token));
    s_factory.pauseClaimContract(address(s_token));
    assertEq(s_factory.isClaimContractPaused(address(s_token)), true);
  }
}
