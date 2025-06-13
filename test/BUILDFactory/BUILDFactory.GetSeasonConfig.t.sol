// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../BaseTest.t.sol";

contract BUILDFactoryGetSeasonUnlockStartTimeTest is BaseTest {
  function test_WhenTheSeasonDoesNotExist() external view {
    // it should return default values
    uint256 unlockStartsAt = s_factory.getSeasonUnlockStartTime(0);
    assertEq(unlockStartsAt, 0);
  }
}
