// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseInvariant} from "./BaseInvariant.t.sol";
import {IBUILDClaim} from "../../src/interfaces/IBUILDClaim.sol";

contract BUILDClaimInvariants is BaseInvariant {
  function _validateClaimAmount(
    IBUILDClaim.UserState memory state,
    uint256 maxAmount,
    bool seasonHasEarly
  ) internal pure {
    assertTrue(
      state.claimed <= maxAmount
        || (state.claimed > maxAmount && !state.hasEarlyClaimed && seasonHasEarly),
      "Invariant violated: claimed amount can only exceed max token amount when user has not early claimed and others have"
    );

    assertTrue(
      !state.hasEarlyClaimed || state.claimed < maxAmount,
      "Invariant violated: early claimed user must have less than max amount"
    );
  }

  function invariant_cannotClaimMoreThanMaxTokenAmount() public view {
    uint256 maxSeasonId = s_handler.getNextSeasonId() - 1;
    for (uint256 seasonId = 1; seasonId <= maxSeasonId; ++seasonId) {
      IBUILDClaim.UserSeasonId[] memory usersAndSeasonIds = new IBUILDClaim.UserSeasonId[](3);
      usersAndSeasonIds[0] = IBUILDClaim.UserSeasonId(USER_1, seasonId);
      usersAndSeasonIds[1] = IBUILDClaim.UserSeasonId(USER_2, seasonId);
      usersAndSeasonIds[2] = IBUILDClaim.UserSeasonId(USER_MSIG, seasonId);

      IBUILDClaim.UserState[] memory p1 = s_claim.getUserState(usersAndSeasonIds);
      IBUILDClaim.UserState[] memory p2 = s_claim_2.getUserState(usersAndSeasonIds);

      bool hasEarlyP1 = p1[0].hasEarlyClaimed || p1[1].hasEarlyClaimed || p1[2].hasEarlyClaimed;
      bool hasEarlyP2 = p2[0].hasEarlyClaimed || p2[1].hasEarlyClaimed || p2[2].hasEarlyClaimed;

      _validateClaimAmount(p1[0], MAX_TOKEN_AMOUNT_P1_S1_U1, hasEarlyP1);
      _validateClaimAmount(p1[1], MAX_TOKEN_AMOUNT_P1_S1_U2, hasEarlyP1);
      _validateClaimAmount(p1[2], MAX_TOKEN_AMOUNT_P1_S1_MSIG, hasEarlyP1);
      _validateClaimAmount(p2[0], MAX_TOKEN_AMOUNT_P2_S1_U1, hasEarlyP2);
      _validateClaimAmount(p2[1], MAX_TOKEN_AMOUNT_P2_S1_U2, hasEarlyP2);
      _validateClaimAmount(p2[2], MAX_TOKEN_AMOUNT_P2_S1_MSIG, hasEarlyP2);
    }
  }

  function invariant_claimTokenBalanceIsNeverBelowTotalClaimableAmounts() public view {
    uint256 maxSeasonId = s_handler.getNextSeasonId() - 1;
    uint256 claimableP1;
    uint256 claimableP2;
    for (uint256 seasonId = 1; seasonId <= maxSeasonId; ++seasonId) {
      claimableP1 +=
        s_claim.getCurrentClaimValues(USER_1, seasonId, MAX_TOKEN_AMOUNT_P1_S1_U1).claimable;
      claimableP1 +=
        s_claim.getCurrentClaimValues(USER_2, seasonId, MAX_TOKEN_AMOUNT_P1_S1_U2).claimable;
      claimableP1 +=
        s_claim.getCurrentClaimValues(USER_MSIG, seasonId, MAX_TOKEN_AMOUNT_P1_S1_MSIG).claimable;
      claimableP2 +=
        s_claim_2.getCurrentClaimValues(USER_1, seasonId, MAX_TOKEN_AMOUNT_P2_S1_U1).claimable;
      claimableP2 +=
        s_claim_2.getCurrentClaimValues(USER_2, seasonId, MAX_TOKEN_AMOUNT_P2_S1_U2).claimable;
      claimableP2 +=
        s_claim_2.getCurrentClaimValues(USER_MSIG, seasonId, MAX_TOKEN_AMOUNT_P2_S1_MSIG).claimable;
    }

    assertLe(
      (s_factory.calcMaxAvailableAmount(address(s_token)) + claimableP1),
      s_token.balanceOf(address(s_claim)),
      "Invariant violated: total claimable + refundable tokens exceeds contract token 1 balance"
    );
    assertLe(
      s_factory.calcMaxAvailableAmount(address(s_token_2)) + claimableP2,
      s_token_2.balanceOf(address(s_claim_2)),
      "Invariant violated: total claimable + refundable tokens exceeds contract token 2 balance"
    );
  }

  function invariant_gettersShouldNotRevert() public view {
    s_claim.getFactory();
    s_claim_2.getFactory();
    s_claim.getToken();
    s_claim_2.getToken();
    uint256 maxSeasonId = s_handler.getNextSeasonId() - 1;
    for (uint256 seasonId = 1; seasonId <= maxSeasonId; ++seasonId) {
      // getUserState is tested in invariant_cannotClaimMoreThanMaxTokenAmount
      // getCurrentClaimValues is tested in
      // invariant_claimTokenBalanceIsNeverBelowTotalClaimableAmounts
      s_claim.getGlobalState(seasonId);
      s_claim_2.getGlobalState(seasonId);
    }
  }

  // added to be excluded from coverage report
  function test() public override {}
}
