// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {IBUILDClaim} from "../src/interfaces/IBUILDClaim.sol";

contract Utils is Test {
  function _changePrank(
    address newCaller
  ) internal {
    vm.stopPrank();
    vm.startPrank(newCaller, DEFAULT_SENDER); // change only msg.sender
  }

  function _changePrankTxOrigin(
    address newCaller
  ) internal {
    vm.stopPrank();
    vm.startPrank(newCaller, newCaller); // change both msg.sender and tx.origin
  }

  function _singleUserState(
    address user,
    uint256 season
  ) internal pure returns (IBUILDClaim.UserSeasonId[] memory) {
    IBUILDClaim.UserSeasonId[] memory inputs = new IBUILDClaim.UserSeasonId[](1);
    inputs[0] = IBUILDClaim.UserSeasonId(user, season);

    return inputs;
  }

  // added to be excluded from coverage report
  function test() public virtual {}
}
