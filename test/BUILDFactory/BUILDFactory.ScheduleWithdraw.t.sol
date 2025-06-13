// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

/// @notice Requirements
/// [BUS10.1](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=320a0b93-347d-42a1-a3b2-54f5254b1f70&fieldId=28d1c574-a71d-5e3e-babb-d23bb4454358)
/// [BUS10.2](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=2e0a11f5-29df-402e-bad3-4b225c0a251d&fieldId=28d1c574-a71d-5e3e-babb-d23bb4454358)
contract BUILDFactoryScheduleWithdrawTest is BaseTest {
  function test_RevertWhen_TheCallerIsNotFactoryAdmin()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
  {
    _changePrank(NOBODY);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        NOBODY,
        s_factory.DEFAULT_ADMIN_ROLE()
      )
    );
    s_factory.scheduleWithdraw(address(s_token), PROJECT_ADMIN, 10);
  }

  modifier whenTheCallerIsFactoryAdmin() {
    _changePrank(ADMIN);
    _;
  }

  function test_RevertWhen_WithdrawalRecipientIsZeroAddress()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsFactoryAdmin
  {
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(IBUILDFactory.InvalidWithdrawalRecipient.selector, address(0))
    );
    s_factory.scheduleWithdraw(address(s_token), address(0), 10);
  }

  function test_RevertWhen_WithdrawalAmountIsZero()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsFactoryAdmin
  {
    uint256 maxAvailableAmount = s_factory.calcMaxAvailableAmount(address(s_token));
    assertEq(maxAvailableAmount, 0);
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.InvalidWithdrawalAmount.selector, 0, 0));
    s_factory.scheduleWithdraw(address(s_token), PROJECT_ADMIN, 0);
  }

  function test_RevertWhen_WithdrawalAmountExceedsTheMaxAvailableAmount()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenTheCallerIsFactoryAdmin
  {
    uint256 maxAvailable = s_factory.calcMaxAvailableAmount(address(s_token));
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.InvalidWithdrawalAmount.selector, maxAvailable + 1, maxAvailable
      )
    );
    s_factory.scheduleWithdraw(address(s_token), PROJECT_ADMIN, maxAvailable + 1);
  }

  function test_WhenTheresAnExistingSchedule()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenTheCallerIsFactoryAdmin
  {
    // it should overwrite the existing withdrawal
    s_factory.scheduleWithdraw(address(s_token), PROJECT_ADMIN_2, 1);
    s_factory.scheduleWithdraw(address(s_token), PROJECT_ADMIN, 10);

    IBUILDFactory.Withdrawal memory withdrawal = s_factory.getScheduledWithdrawal(address(s_token));
    assertEq(withdrawal.recipient, PROJECT_ADMIN);
    assertEq(withdrawal.amount, 10);
  }

  function test_WhenWithdrawalParamsAreValid()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenTheCallerIsFactoryAdmin
  {
    // it should schedule a withdrawal
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.WithdrawalScheduled(address(s_claim.getToken()), PROJECT_ADMIN, 10);
    s_factory.scheduleWithdraw(address(s_token), PROJECT_ADMIN, 10);

    IBUILDFactory.Withdrawal memory withdrawal = s_factory.getScheduledWithdrawal(address(s_token));
    assertEq(withdrawal.recipient, PROJECT_ADMIN);
    assertEq(withdrawal.amount, 10);
  }

  function test_WhenClaimContractIsPaused()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenPauserHasFactoryPauserRole(PAUSER)
  {
    IBUILDFactory.TokenAmounts memory amounts = s_factory.getTokenAmounts(address(s_token));
    uint256 maxAvailable = s_factory.calcMaxAvailableAmount(address(s_token));
    assertEq(amounts.totalDeposited, TOKEN_AMOUNT_P1_S1 + TOKEN_AMOUNT_P1_S2);
    assertEq(maxAvailable, amounts.totalDeposited - amounts.totalAllocatedToAllSeasons);

    // if trying to schedule a withdraw for total deposit, it should revert
    _changePrank(ADMIN);
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.InvalidWithdrawalAmount.selector, amounts.totalDeposited, maxAvailable
      )
    );
    s_factory.scheduleWithdraw(address(s_token), PROJECT_ADMIN, amounts.totalDeposited);

    // pause the claim contract
    _changePrank(PAUSER);
    s_factory.pauseClaimContract(address(s_token));

    // it should schedule the withdrawal
    _changePrank(ADMIN);
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.WithdrawalScheduled(address(s_token), PROJECT_ADMIN, amounts.totalDeposited);
    s_factory.scheduleWithdraw(address(s_token), PROJECT_ADMIN, amounts.totalDeposited);
    IBUILDFactory.Withdrawal memory withdrawal = s_factory.getScheduledWithdrawal(address(s_token));
    assertEq(withdrawal.recipient, PROJECT_ADMIN);
    assertEq(withdrawal.amount, amounts.totalDeposited);
  }
}
