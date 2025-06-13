// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseInvariant} from "./BaseInvariant.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

contract BUILDFactoryInvariants is BaseInvariant {
  function invariant_withdrawalAmountCannotExceedContractTokenBalance() public view {
    uint256 maxWithdrawable = s_factory.calcMaxAvailableAmount(address(s_token));
    assertLe(
      maxWithdrawable,
      s_token.balanceOf(address(s_claim)),
      "Invariant violated: max withdrawable amount exceeds contract token balance"
    );
    maxWithdrawable = s_factory.calcMaxAvailableAmount(address(s_token_2));
    assertLe(
      maxWithdrawable,
      s_token_2.balanceOf(address(s_claim_2)),
      "Invariant violated: max withdrawable amount exceeds contract token balance"
    );
  }

  function invariant_tokenValidationCalculationsDoNotUnderflow() public view {
    IBUILDFactory.TokenAmounts memory tokenAmounts = s_factory.getTokenAmounts(address(s_token));
    assertLe(
      tokenAmounts.totalRefunded,
      tokenAmounts.totalAllocatedToAllSeasons,
      "Invariant violated: total refunded amount exceeds total allocated to all seasons"
    );
    assertLe(
      tokenAmounts.totalWithdrawn,
      tokenAmounts.totalDeposited,
      "Invariant violated: total withdrawn amount exceeds total deposited amount"
    );
    assertLe(
      tokenAmounts.totalWithdrawn,
      tokenAmounts.totalDeposited + tokenAmounts.totalRefunded
        - tokenAmounts.totalAllocatedToAllSeasons,
      "Invariant violated: total withdrawn amount exceeds max possible withdrawable amount"
    );
    assertGe(
      tokenAmounts.totalDeposited + tokenAmounts.totalRefunded,
      tokenAmounts.totalAllocatedToAllSeasons + tokenAmounts.totalWithdrawn,
      "Invariant violated: total deposited and refunded amount does not exceed total allocated and withdrawn amount"
    );

    tokenAmounts = s_factory.getTokenAmounts(address(s_token_2));
    assertLe(
      tokenAmounts.totalRefunded,
      tokenAmounts.totalAllocatedToAllSeasons,
      "Invariant violated: total refunded amount exceeds total allocated to all seasons"
    );
    assertLe(
      tokenAmounts.totalWithdrawn,
      tokenAmounts.totalDeposited,
      "Invariant violated: total withdrawn amount exceeds total deposited amount"
    );
    assertLe(
      tokenAmounts.totalWithdrawn,
      tokenAmounts.totalDeposited + tokenAmounts.totalRefunded
        - tokenAmounts.totalAllocatedToAllSeasons,
      "Invariant violated: total withdrawn amount exceeds max possible withdrawable amount"
    );
    assertGe(
      tokenAmounts.totalDeposited + tokenAmounts.totalRefunded,
      tokenAmounts.totalAllocatedToAllSeasons + tokenAmounts.totalWithdrawn,
      "Invariant violated: total deposited and refunded amount does not exceed total allocated and withdrawn amount"
    );
  }

  function invariant_gettersShouldNotRevert() public view {
    s_factory.getProjects();
    s_factory.getUnlockConfigMaxValues();
    s_factory.getProjectConfig(address(s_token));
    s_factory.getProjectConfig(address(s_token_2));
    s_factory.isClaimContractPaused(address(s_token));
    s_factory.isClaimContractPaused(address(s_token_2));
    s_factory.getTokenAmounts(address(s_token));
    s_factory.getTokenAmounts(address(s_token_2));
    s_factory.calcMaxAvailableAmount(address(s_token));
    s_factory.calcMaxAvailableAmount(address(s_token_2));
    s_factory.getScheduledWithdrawal(address(s_token));
    s_factory.getScheduledWithdrawal(address(s_token_2));
    uint256 maxSeasonId = s_handler.getNextSeasonId() - 1;
    for (uint256 seasonId = 1; seasonId <= maxSeasonId; ++seasonId) {
      s_factory.getSeasonUnlockStartTime(seasonId);
      s_factory.getProjectSeasonConfig(address(s_token), seasonId);
      s_factory.getProjectSeasonConfig(address(s_token_2), seasonId);
      s_factory.isRefunding(address(s_token), seasonId);
      s_factory.isRefunding(address(s_token_2), seasonId);
      s_factory.getRefundableAmount(address(s_token), seasonId);
      s_factory.getRefundableAmount(address(s_token_2), seasonId);
    }
  }

  // added to be excluded from coverage report
  function test() public override {}
}
