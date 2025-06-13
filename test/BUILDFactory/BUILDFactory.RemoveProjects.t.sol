// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";
import {Closable} from "./../../src/Closable.sol";

/// @notice Requirements
/// [BUS1.1](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=e4dc7ee5-a590-4f36-8af1-183c3b71aa96&fieldId=3518969f-7efc-47be-8d27-eae795fd6e14)
/// [BUS1.2](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=43de4ece-733f-4aa0-87e6-88010484a470&fieldId=28d1c574-a71d-5e3e-babb-d23bb4454358)
/// [BUS1.4](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=ff67a747-c032-45c2-a31d-8f87ed239989)
contract BUILDFactoryRemoveProjectsTest is BaseTest {
  function setUp() public {
    _changePrank(ADMIN);
    IBUILDFactory.AddProjectParams[] memory input = new IBUILDFactory.AddProjectParams[](1);
    input[0] = IBUILDFactory.AddProjectParams({token: address(s_token), admin: PROJECT_ADMIN});
  }

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
    address[] memory input;
    s_factory.removeProjects(input);
  }

  modifier whenTheCallerHasTheDEFAULT_ADMIN_ROLE() {
    _changePrank(ADMIN);
    _;
  }

  function test_RevertWhen_TheProjectHasNotBeenAdded()
    external
    whenTheCallerHasTheDEFAULT_ADMIN_ROLE
  {
    address[] memory removals = new address[](1);
    removals[0] = address(1);
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.ProjectDoesNotExist.selector, address(1)));
    s_factory.removeProjects(removals);
  }

  function test_RevertWhen_TheFactoryIsClosed()
    external
    whenProjectAddedAndClaimDeployed
    whenFactoryClosed
    whenTheCallerHasTheDEFAULT_ADMIN_ROLE
  {
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(Closable.AlreadyClosed.selector));
    address[] memory removals = new address[](1);
    removals[0] = address(s_token);
    s_factory.removeProjects(removals);
  }

  function test_WhenTheProjectHasBeenAdded() external whenTheCallerHasTheDEFAULT_ADMIN_ROLE {
    IBUILDFactory.AddProjectParams[] memory input = new IBUILDFactory.AddProjectParams[](2);
    input[0] = IBUILDFactory.AddProjectParams({token: address(s_token), admin: PROJECT_ADMIN});
    input[1] = IBUILDFactory.AddProjectParams({token: address(s_token_2), admin: PROJECT_ADMIN});
    s_factory.addProjects(input);
    address[] memory removals = new address[](1);
    removals[0] = address(s_token);

    // it should emit a ProjectRemoved event
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.ProjectRemoved(address(s_token));
    s_factory.removeProjects(removals);
    address[] memory projects = s_factory.getProjects();
    // it should remove the project from the projects list
    assertEq(projects.length, 1);
    assertEq(projects[0], address(s_token_2));
    // it should unset the project admin address for the project
    IBUILDFactory.ProjectConfig memory projectConfig = s_factory.getProjectConfig(address(s_token));
    assertEq(projectConfig.admin, address(0));
    assertEq(address(projectConfig.claim), address(0));
  }
}
