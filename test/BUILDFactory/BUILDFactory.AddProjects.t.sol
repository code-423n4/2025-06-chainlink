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
/// [BUS9](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=610ae7f5-cfb4-4207-bc27-678333004707)
contract BUILDFactoryAddProjectsTest is BaseTest {
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
    IBUILDFactory.AddProjectParams[] memory input;
    s_factory.addProjects(input);
  }

  function test_RevertWhen_TheFactoryIsClosed() external whenFactoryClosed {
    _changePrank(ADMIN);
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(Closable.AlreadyClosed.selector));
    IBUILDFactory.AddProjectParams[] memory input;
    s_factory.addProjects(input);
  }

  function test_RevertWhen_AddedAdminIsAddress_0() external {
    _changePrank(ADMIN);
    IBUILDFactory.AddProjectParams[] memory input = new IBUILDFactory.AddProjectParams[](1);
    input[0] = IBUILDFactory.AddProjectParams({token: address(s_token), admin: address(0)});
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.InvalidAddProjectParams.selector));
    s_factory.addProjects(input);
  }

  function test_RevertWhen_AddedTokenIsAddress_0() external {
    _changePrank(ADMIN);
    IBUILDFactory.AddProjectParams[] memory input = new IBUILDFactory.AddProjectParams[](1);
    input[0] = IBUILDFactory.AddProjectParams({token: address(0), admin: PROJECT_ADMIN});
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.InvalidAddProjectParams.selector));
    s_factory.addProjects(input);
  }

  function test_RevertWhen_AddedTokenIsNotERC20() external {
    _changePrank(ADMIN);
    IBUILDFactory.AddProjectParams[] memory input = new IBUILDFactory.AddProjectParams[](1);
    input[0] = IBUILDFactory.AddProjectParams({token: PROJECT_ADMIN, admin: PROJECT_ADMIN});
    // it should revert
    vm.expectRevert();
    s_factory.addProjects(input);
  }

  function test_WhenProjectDoesNotExist() external {
    _changePrank(ADMIN);
    IBUILDFactory.AddProjectParams[] memory input = new IBUILDFactory.AddProjectParams[](1);
    input[0] = IBUILDFactory.AddProjectParams({token: address(s_token), admin: PROJECT_ADMIN});

    // it should emit a ProjectAddedOrAdminChanged event
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.ProjectAddedOrAdminChanged(address(s_token), PROJECT_ADMIN);
    s_factory.addProjects(input);
    // it should add the project to the projects list
    assertEq(s_factory.getProjects()[0], address(s_token));
    // it should set the project admin address for the project
    IBUILDFactory.ProjectConfig memory config = s_factory.getProjectConfig(address(s_token));
    assertEq(config.admin, PROJECT_ADMIN);
  }

  function test_WhenProjectExists() external {
    _changePrank(ADMIN);
    IBUILDFactory.AddProjectParams[] memory input = new IBUILDFactory.AddProjectParams[](2);
    input[0] = IBUILDFactory.AddProjectParams({token: address(s_token), admin: PROJECT_ADMIN});
    input[1] = IBUILDFactory.AddProjectParams({token: address(s_token_2), admin: PROJECT_ADMIN_2});
    s_factory.addProjects(input);

    input = new IBUILDFactory.AddProjectParams[](1);
    input[0] = IBUILDFactory.AddProjectParams({token: address(s_token), admin: PROJECT_ADMIN_2});
    // it should emit a ProjectAddedOrAdminChanged event
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.ProjectAddedOrAdminChanged(address(s_token), PROJECT_ADMIN_2);
    s_factory.addProjects(input);
    // it should not modify the projects list
    assertEq(s_factory.getProjects()[0], address(s_token));
    assertEq(s_factory.getProjects()[1], address(s_token_2));
    assertEq(s_factory.getProjects().length, 2);
    // it should update the project admin address for the project
    assertEq(s_factory.getProjectConfig(address(s_token)).admin, PROJECT_ADMIN_2);
  }
}
