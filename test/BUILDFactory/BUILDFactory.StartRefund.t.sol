// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

/// @notice Requirements
/// [BUS14.2](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=d15ede14-7622-4593-bd85-540c020aa4cc)
/// [LEG4.2](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=228b0e02-5efb-4bb3-990b-a4c00c896e79)
/// [LEG4.4](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=18e7f181-4177-4cdb-9d73-9b0b9ee05392)
contract BUILDFactoryStartRefundTest is BaseTest {
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
    s_factory.startRefund(address(s_token), SEASON_ID_S1);
  }

  function test_RevertWhen_ProjectSeasonDoesNotExist() external {
    _changePrank(ADMIN);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.ProjectSeasonDoesNotExist.selector, SEASON_ID_S1, address(s_token)
      )
    );
    s_factory.startRefund(address(s_token), SEASON_ID_S1);
  }

  function test_RevertWhen_ProjectSeasonIsRefunding()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenProjectSeasonIsRefunding
  {
    _changePrank(ADMIN);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.ProjectSeasonIsRefunding.selector, address(s_token), SEASON_ID_S1
      )
    );
    s_factory.startRefund(address(s_token), SEASON_ID_S1);
  }

  function test_WhenTheCallerHasTheDEFAULT_ADMIN_ROLE()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
  {
    _changePrank(ADMIN);
    assertEq(s_factory.isRefunding(address(s_token), SEASON_ID_S1), false);

    // it should start refunding
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.ProjectSeasonRefundStarted(address(s_token), SEASON_ID_S1);
    s_factory.startRefund(address(s_token), SEASON_ID_S1);
    assertEq(s_factory.isRefunding(address(s_token), SEASON_ID_S1), true);
  }
}
