// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";
import {Closable} from "./../../src/Closable.sol";

/// @notice Requirements
/// [BUS1.3](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?entryId=173d5734-15a2-4fde-a049-d688f3246006)
/// [BUS2.6](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?entryId=577087a2-3ee0-4205-ac69-966bc2097eaa)
contract BUILDFactorySetSeasonUnlockStartTimeTest is BaseTest {
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
    s_factory.setSeasonUnlockStartTime(SEASON_ID_S1, block.timestamp);
  }

  modifier whenTheCallerHasTheDEFAULT_ADMIN_ROLE() {
    _changePrank(ADMIN);
    _;
  }

  function test_RevertWhen_TheFactoryIsClosed()
    external
    whenFactoryClosed
    whenTheCallerHasTheDEFAULT_ADMIN_ROLE
  {
    uint256 unlockStartsAt = block.timestamp + 1000;
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(Closable.AlreadyClosed.selector));
    s_factory.setSeasonUnlockStartTime(SEASON_ID_S1, unlockStartsAt);
  }

  function test_RevertWhen_TheUnlockStartsAtIsInThePast()
    external
    whenTheCallerHasTheDEFAULT_ADMIN_ROLE
  {
    uint256 unlockStartsAt = block.timestamp - 1;
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.InvalidUnlockStartsAt.selector, SEASON_ID_S1, unlockStartsAt
      )
    );
    s_factory.setSeasonUnlockStartTime(SEASON_ID_S1, unlockStartsAt);
  }

  function test_RevertWhen_TheSeasonHasAlreadyUnlocked()
    external
    whenTheCallerHasTheDEFAULT_ADMIN_ROLE
  {
    uint256 TIME_UNTIL_UNLOCK = 1000;
    uint256 unlockStartsAt = block.timestamp + TIME_UNTIL_UNLOCK;
    // it should emit a SeasonUnlockStartTimeUpdated event
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.SeasonUnlockStartTimeUpdated(SEASON_ID_S1, unlockStartsAt);
    s_factory.setSeasonUnlockStartTime(SEASON_ID_S1, unlockStartsAt);

    skip(TIME_UNTIL_UNLOCK + 1);

    // it should revert
    uint256 newUnlockStartsAt = block.timestamp + 1000;
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.InvalidUnlockStartsAt.selector, SEASON_ID_S1, newUnlockStartsAt
      )
    );
    s_factory.setSeasonUnlockStartTime(SEASON_ID_S1, newUnlockStartsAt);
  }

  function test_WhenTheUnlockStartsAtIsInTheFuture() external whenTheCallerHasTheDEFAULT_ADMIN_ROLE {
    uint256 unlockStartsAt = block.timestamp + 1000;

    // it should emit a SeasonUnlockStartTimeUpdated event
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.SeasonUnlockStartTimeUpdated(SEASON_ID_S1, unlockStartsAt);
    s_factory.setSeasonUnlockStartTime(SEASON_ID_S1, unlockStartsAt);

    // it should set the season config
    uint256 latestUnlockStartTime = s_factory.getSeasonUnlockStartTime(SEASON_ID_S1);
    assertEq(latestUnlockStartTime, unlockStartsAt);
  }
}
