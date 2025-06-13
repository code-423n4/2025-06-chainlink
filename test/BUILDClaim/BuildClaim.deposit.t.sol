// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDClaim} from "../../src/interfaces/IBUILDClaim.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";
import {Closable} from "./../../src/Closable.sol";

/// @notice Requirements
/// [BUS1.6](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=1653eb50-6aaf-4a8c-904d-e7e3a46f4016)
/// [BUS12.1.1.1](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=123f14c2-3d98-4022-8eac-af2bf580bd5a)
/// [BUS12.1.1](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?entryId=c09420d0-5086-461f-8ca8-e8a469ddb017)
/// [LEG7](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=a980d08d-4143-4e1c-ba29-8c5b0d760f24)
/// [LEG8](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=a45dcc4a-f969-4219-9c83-89fc25f93951)
/// [LEG9](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=57cb08e0-0647-446c-b999-fac41594ed40)
contract BUILDClaimDepositTest is BaseTest {
  function test_RevertWhen_TheCallerIsNotTheProjectAdmin()
    external
    whenProjectAddedAndClaimDeployed
  {
    _changePrank(NOBODY);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector, NOBODY, keccak256("PROJECT_ADMIN")
      )
    );
    s_claim.deposit(100);
  }

  modifier whenTheCallerIsTheProjectAdmin() {
    _changePrank(PROJECT_ADMIN);
    _;
  }

  function test_RevertWhen_TheCallerHasNotApprovedSufficientAllowance()
    external
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsTheProjectAdmin
  {
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientAllowance.selector, address(s_claim), 0, 100
      )
    );
    s_claim.deposit(100);
  }

  function test_RevertWhen_TheContractIsPaused()
    external
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsTheProjectAdmin
    whenPauserHasFactoryPauserRole(PAUSER)
  {
    s_token.approve(address(s_claim), 100);

    // Pause the contract from the factory
    _changePrank(PAUSER);
    s_factory.pauseClaimContract(address(s_token));

    // it should revert
    _changePrank(PROJECT_ADMIN);
    vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
    s_claim.deposit(100);
  }

  function test_RevertWhen_TheFactoryIsClosed()
    external
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsTheProjectAdmin
    whenFactoryClosed
  {
    s_token.approve(address(s_claim), 100);

    // it should revert
    _changePrank(PROJECT_ADMIN);
    vm.expectRevert(abi.encodeWithSelector(Closable.AlreadyClosed.selector));
    s_claim.deposit(100);
  }

  function test_WhenTheCallerHasApprovedSufficientAllowance()
    external
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsTheProjectAdmin
  {
    s_token.approve(address(s_claim), 100);
    // it should deposit the project tokens to the claim contract
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.ProjectTotalDepositedIncreased(address(s_token), address(s_claim), 100, 100);
    vm.expectEmit(address(s_claim));
    emit IBUILDClaim.Deposited(address(s_token), PROJECT_ADMIN, 100, 100);
    s_claim.deposit(100);
  }

  function test_RevertWhen_TheTokenTriesToReenter()
    external
    whenReentrantProjectAddedAndClaimDeployed
  {
    address projectAdmin = address(s_token_reentrant);
    _changePrank(projectAdmin);
    bytes memory data = abi.encodeWithSelector(IBUILDClaim.deposit.selector, TOKEN_AMOUNT_P1_S1);
    s_token_reentrant.enableRentrancy(address(s_claim_reentrant), data);

    // it should revert
    vm.expectRevert(abi.encodeWithSelector(ReentrancyGuard.ReentrancyGuardReentrantCall.selector));
    s_claim_reentrant.deposit(TOKEN_AMOUNT_P1_S1);
  }

  function test_RevertWhen_TheTokenTransferIsInvalid()
    external
    whenInvalidTransferProjectAddedAndClaimDeployed
  {
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDClaim.InvalidDeposit.selector, 0, 0));
    s_claim_invalidTransfer.deposit(TOKEN_AMOUNT_P1_S1);
  }

  function test_RevertWhen_TheTokenHasFeeOnTransfer()
    external
    whenFeeOnTransferProjectAddedAndClaimDeployed
  {
    uint256 amount = 100;
    uint256 fee = 1; // 1% fee
    uint256 amountAfterFee = amount - fee;
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDClaim.InvalidDeposit.selector, 0, amountAfterFee));
    s_claim_feeOnTransfer.deposit(amount);
  }
}
