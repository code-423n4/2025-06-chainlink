// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Closable} from "./../../src/Closable.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";
import {IBUILDClaim} from "../../src/interfaces/IBUILDClaim.sol";

/// @notice Requirements
/// [BUS1.2.1](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?entryId=8b302488-34f0-4974-ae74-4abb837f3dfe)
/// [BUS5.1](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?entryId=e290457e-b29c-4ad1-85c7-16d72b9b9cce)
/// [BUS9.1](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=40cf6777-49bc-47b1-b833-3d301d3748ae)
contract BUILDFactoryDeployClaimTest is BaseTest {
  function test_RevertWhen_TheProjectIsNotAllowlisted() external {
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(IBUILDFactory.ProjectDoesNotExist.selector, address(s_token))
    );
    s_factory.deployClaim(address(s_token));
  }

  function test_RevertWhen_TheCallerIsNotAProjectAdmin() external whenProjectAdded {
    _changePrank(NOBODY);
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.Unauthorized.selector));
    s_factory.deployClaim(address(s_token));
  }

  function test_RevertWhen_AClaimContractForTheTokenIsAlreadyDeployed() external whenProjectAdded {
    _changePrank(PROJECT_ADMIN);
    s_factory.deployClaim(address(s_token));
    // it should revert

    IBUILDFactory.ProjectConfig memory config = s_factory.getProjectConfig(address(s_token));
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.ClaimAlreadyExists.selector, address(s_token), address(config.claim)
      )
    );
    s_factory.deployClaim(address(s_token));
  }

  function test_RevertWhen_TheFactoryIsPaused() external whenProjectAdded whenFactoryPaused(PAUSER) {
    _changePrank(PROJECT_ADMIN);
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
    s_factory.deployClaim(address(s_token));
  }

  function test_RevertWhen_TheFactoryIsClosed() external whenProjectAdded whenFactoryClosed {
    _changePrank(PROJECT_ADMIN);
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(Closable.AlreadyClosed.selector));
    s_factory.deployClaim(address(s_token));
  }

  function test_WhenTheCallerIsTheProjectAdmin() external whenProjectAdded {
    _changePrank(PROJECT_ADMIN);

    // it should emit a ClaimDeployed event
    vm.expectEmit(true, false, true, false, address(s_factory));
    emit IBUILDFactory.ClaimDeployed(address(s_token), address(0));
    // it should return the new claim contract address
    IBUILDClaim claim = s_factory.deployClaim(address(s_token));

    // it should deploy a new claim contract
    assertEq(address(claim.getToken()), address(s_token));
    // it should set the claim contract address for the project
    IBUILDFactory.ProjectConfig memory config = s_factory.getProjectConfig(address(s_token));
    assertEq(address(config.claim), address(claim));
    assertEq(address(claim.getFactory()), address(s_factory));
    assertTrue(claim.supportsInterface(type(IBUILDClaim).interfaceId));
  }
}
