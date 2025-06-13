// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDClaim} from "../../src/interfaces/IBUILDClaim.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

/// @notice Requirements
/// [BUS10.1](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=320a0b93-347d-42a1-a3b2-54f5254b1f70&fieldId=28d1c574-a71d-5e3e-babb-d23bb4454358)
/// [BUS10.2](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=2e0a11f5-29df-402e-bad3-4b225c0a251d&fieldId=28d1c574-a71d-5e3e-babb-d23bb4454358)
/// [LEG4.2](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=228b0e02-5efb-4bb3-990b-a4c00c896e79)
/// [LEG8](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=a45dcc4a-f969-4219-9c83-89fc25f93951)
/// [LEG9](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=57cb08e0-0647-446c-b999-fac41594ed40)
contract BUILDClaimWithdrawTest is BaseTest {
  function test_RevertWhen_TheCallerIsNotProjectAdmin()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
  {
    _changePrank(NOBODY);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector, NOBODY, keccak256("PROJECT_ADMIN")
      )
    );
    s_claim.withdraw();
  }

  modifier whenTheCallerIsProjectAdmin() {
    _changePrank(PROJECT_ADMIN);
    _;
  }

  function test_RevertWhen_NoWithdrawalIsScheduled()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsProjectAdmin
  {
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(IBUILDFactory.WithdrawalDoesNotExist.selector, address(s_token))
    );
    s_claim.withdraw();
  }

  function test_WhenWithdrawalIsScheduled()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenDepositedAndWithdrawalScheduled
    whenTheCallerIsProjectAdmin
  {
    // check token balance before
    uint256 balanceBefore = s_token.balanceOf(PROJECT_ADMIN);

    // it should withdraw
    vm.expectEmit(address(s_claim));
    emit IBUILDClaim.Withdrawn(address(s_token), PROJECT_ADMIN, 10, 10);
    s_claim.withdraw();

    // check token balance after
    assertEq(s_token.balanceOf(PROJECT_ADMIN) - balanceBefore, 10);

    // it should reset the pending withdrawal
    IBUILDFactory.Withdrawal memory withdrawal = s_factory.getScheduledWithdrawal(address(s_token));
    assertEq(withdrawal.amount, 0);
    assertEq(withdrawal.recipient, address(0));
  }

  function test_WhenClaimContractIsPaused()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenClaimPaused(PAUSER, address(s_token))
  {
    _changePrank(ADMIN);
    IBUILDFactory.TokenAmounts memory amounts = s_factory.getTokenAmounts(address(s_token));
    uint256 maxAvailable = s_factory.calcMaxAvailableAmount(address(s_token));
    assertEq(amounts.totalDeposited, TOKEN_AMOUNT_P1_S1 + TOKEN_AMOUNT_P1_S2);
    assertEq(amounts.totalAllocatedToAllSeasons, TOKEN_AMOUNT_P1_S1);
    assertEq(maxAvailable, amounts.totalDeposited - amounts.totalAllocatedToAllSeasons);
    assertEq(s_token.balanceOf(address(s_claim)), amounts.totalDeposited);

    uint256 projectAdminBalanceBefore = s_token.balanceOf(PROJECT_ADMIN);
    s_factory.scheduleWithdraw(address(s_token), PROJECT_ADMIN, amounts.totalDeposited);

    // it should withdraw
    _changePrank(PROJECT_ADMIN);
    vm.expectEmit(address(s_claim));
    emit IBUILDClaim.Withdrawn(
      address(s_token), PROJECT_ADMIN, amounts.totalDeposited, amounts.totalDeposited
    );
    s_claim.withdraw();
    assertEq(s_token.balanceOf(address(s_claim)), 0);
    assertEq(s_token.balanceOf(PROJECT_ADMIN), projectAdminBalanceBefore + amounts.totalDeposited);
  }

  function test_RevertWhen_TheTokenTriesToReenter()
    external
    whenReentrantProjectAddedAndClaimDeployed
  {
    address projectAdmin = address(s_token_reentrant);
    _changePrank(projectAdmin);
    s_token_reentrant.disableReentrancy();
    s_claim_reentrant.deposit(TOKEN_AMOUNT_P1_S1);

    _changePrank(ADMIN);
    s_factory.scheduleWithdraw(address(s_token_reentrant), projectAdmin, TOKEN_AMOUNT_P1_S1);

    _changePrank(projectAdmin);
    bytes memory data = abi.encodeWithSelector(IBUILDClaim.withdraw.selector);
    s_token_reentrant.enableRentrancy(address(s_claim_reentrant), data);

    // it should revert
    vm.expectRevert(abi.encodeWithSelector(ReentrancyGuard.ReentrancyGuardReentrantCall.selector));
    s_claim_reentrant.withdraw();
  }

  modifier whenDepositedAndWithdrawalScheduled() {
    _changePrank(PROJECT_ADMIN);
    s_token.approve(address(s_claim), 10);
    s_claim.deposit(10);

    _changePrank(ADMIN);
    s_factory.scheduleWithdraw(address(s_token), PROJECT_ADMIN, 10);
    _;
  }
}
