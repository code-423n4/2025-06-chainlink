// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

contract BUILDFactoryUnpauseClaimContractTest is BaseTest {
  function test_RevertWhen_TheCallerDoesNotHaveThePAUSER_ROLE()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenClaimPaused(PAUSER, address(s_token))
  {
    _changePrank(NOBODY);
    assertEq(s_factory.hasRole(s_factory.PAUSER_ROLE(), NOBODY), false);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector, NOBODY, s_factory.PAUSER_ROLE()
      )
    );
    s_factory.unpauseClaimContract(address(s_token));
  }

  function test_RevertWhen_TheClaimContractDoesNotExist()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenPauserHasFactoryPauserRole(PAUSER)
    whenClaimPaused(PAUSER, address(s_token))
  {
    _changePrank(ADMIN);
    address[] memory removals = new address[](1);
    removals[0] = address(s_token);
    s_factory.removeProjects(removals);

    _changePrank(PAUSER);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(IBUILDFactory.ProjectDoesNotExist.selector, address(s_token))
    );
    s_factory.unpauseClaimContract(address(s_token));
  }

  function test_RevertWhen_NotPaused()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenPauserHasFactoryPauserRole(PAUSER)
  {
    _changePrank(PAUSER);
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(Pausable.ExpectedPause.selector));
    s_factory.unpauseClaimContract(address(s_token));
  }

  function test_WhenPausedAndTheCallerHasThePAUSER_ROLE()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenClaimPaused(PAUSER, address(s_token))
  {
    _changePrank(PAUSER);
    // it should unpause the contract
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.ClaimUnpaused(address(s_token));
    s_factory.unpauseClaimContract(address(s_token));
    assertEq(s_factory.isClaimContractPaused(address(s_token)), false);
  }
}
