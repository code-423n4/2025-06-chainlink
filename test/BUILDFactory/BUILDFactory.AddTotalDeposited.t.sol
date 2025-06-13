// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

contract BUILDFactoryAddTotalDeposited is BaseTest {
  function test_RevertWhen_TheCallerIsNotFromTheClaimContract() external {
    _changePrank(NOBODY);
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.Unauthorized.selector));
    s_factory.addTotalDeposited(address(s_token), 1);
  }

  function test_RevertWhen_InvalidAmount()
    external
    whenProjectAddedAndClaimDeployed
    whenCallerIsClaimsAddress(address(s_token))
  {
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.InvalidAmount.selector));
    s_factory.addTotalDeposited(address(s_token), 0);
  }

  function test_When_ValidCaller()
    external
    whenProjectAddedAndClaimDeployed
    whenCallerIsClaimsAddress(address(s_token))
  {
    s_factory.addTotalDeposited(address(s_token), 1);
    IBUILDFactory.TokenAmounts memory tokenAmounts = s_factory.getTokenAmounts(address(s_token));
    assertEq(tokenAmounts.totalDeposited, 1);
  }

  modifier whenCallerIsClaimsAddress(
    address project
  ) {
    _changePrank(address(s_factory.getProjectConfig(project).claim));
    _;
  }
}
