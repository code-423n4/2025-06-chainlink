// SPDX-License-Identifier: MIT
// solhint-disable no-console
pragma solidity 0.8.26;

import {ScenarioBuilder} from "../ScenarioBuilder.t.sol";
import {BUILDClaim} from "../../src/BUILDClaim.sol";
import {IBUILDClaim} from "../../src/interfaces/IBUILDClaim.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

contract BUILDClaimGetClaimableState is BUILDClaim, ScenarioBuilder {
  constructor() BUILDClaim(0x2c7cF54991df665C90E8aDeb50b50f98Be4B74B9) {}

  uint256 private constant PERCENTAGE_BASIS_POINTS_DENOMINATOR = 10_000;

  function _validateClaimingAmounts(
    IBUILDClaim.ClaimableState memory claimingAmounts,
    IBUILDClaim.ClaimableState memory targetClaimValues
  ) internal pure {
    assertEq(claimingAmounts.base, targetClaimValues.base);
    assertEq(claimingAmounts.bonus, targetClaimValues.bonus);
    assertEq(claimingAmounts.claimed, targetClaimValues.claimed);
    assertEq(claimingAmounts.vested, targetClaimValues.vested);
    assertEq(claimingAmounts.earlyVestableBonus, targetClaimValues.earlyVestableBonus);
    assertEq(claimingAmounts.loyaltyBonus, targetClaimValues.loyaltyBonus);
    assertEq(claimingAmounts.claimable, targetClaimValues.claimable);
  }

  function test_SingleUserSingleVestedClaim() external whenProjectAddedAndClaimDeployed {
    IBUILDFactory.ProjectSeasonConfig memory config = IBUILDFactory.ProjectSeasonConfig({
      tokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      merkleRoot: bytes32(0),
      unlockDelay: UNLOCK_DELAY_P1_S1,
      unlockDuration: UNLOCK_DURATION_S1,
      earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
      earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
      baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1,
      isRefunding: false
    });
    IBUILDClaim.GlobalState memory globalState =
      IBUILDClaim.GlobalState({totalLoyalty: 0, totalLoyaltyIneligible: 0, totalClaimed: 0});
    BUILDClaim.UserState memory userState =
      IBUILDClaim.UserState({claimed: 0, hasEarlyClaimed: false});
    BUILDClaim.UnlockState memory unlockState = _getUnlockState({
      unlockStartsAt: UNLOCK_START_TIME_S1,
      unlockDelay: UNLOCK_DELAY_P1_S1,
      unlockDuration: UNLOCK_DURATION_S1,
      targetTime: UNLOCK_START_TIME_S1 + UNLOCK_DELAY_P1_S1 + (UNLOCK_DURATION_S1 / 2)
    });
    IBUILDClaim.ClaimableState memory claimingAmounts = _getClaimableState({
      config: config,
      globalState: globalState,
      userState: userState,
      unlockState: unlockState,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1
    });

    uint256 base = BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1 * MAX_TOKEN_AMOUNT_P1_S1_U1
      / PERCENTAGE_BASIS_POINTS_DENOMINATOR;
    uint256 bonus = MAX_TOKEN_AMOUNT_P1_S1_U1 - base;
    IBUILDClaim.ClaimableState memory targetClaimValues = IBUILDClaim.ClaimableState({
      base: base,
      bonus: bonus,
      claimed: 0,
      vested: bonus / 2,
      earlyVestableBonus: 2.25 ether,
      loyaltyBonus: 0,
      claimable: 5.5 ether
    });

    _validateClaimingAmounts(claimingAmounts, targetClaimValues);
  }

  function test_SingleUserDoublePartiallyVestedClaim() external whenProjectAddedAndClaimDeployed {
    IBUILDFactory.ProjectSeasonConfig memory config = IBUILDFactory.ProjectSeasonConfig({
      tokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      merkleRoot: bytes32(0),
      unlockDelay: UNLOCK_DELAY_P1_S1,
      unlockDuration: UNLOCK_DURATION_S1,
      earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
      earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
      baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1,
      isRefunding: false
    });
    IBUILDClaim.GlobalState memory globalState =
      IBUILDClaim.GlobalState({totalLoyalty: 0, totalLoyaltyIneligible: 0, totalClaimed: 0});
    BUILDClaim.UserState memory userState =
      IBUILDClaim.UserState({claimed: 5.5 ether, hasEarlyClaimed: false});
    BUILDClaim.UnlockState memory unlockState = _getUnlockState({
      unlockStartsAt: UNLOCK_START_TIME_S1,
      unlockDelay: UNLOCK_DELAY_P1_S1,
      unlockDuration: UNLOCK_DURATION_S1,
      targetTime: UNLOCK_START_TIME_S1 + UNLOCK_DELAY_P1_S1 + (UNLOCK_DURATION_S1 / 2)
    });
    IBUILDClaim.ClaimableState memory claimingAmounts = _getClaimableState({
      config: config,
      globalState: globalState,
      userState: userState,
      unlockState: unlockState,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1
    });

    uint256 base = BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1 * MAX_TOKEN_AMOUNT_P1_S1_U1
      / PERCENTAGE_BASIS_POINTS_DENOMINATOR;
    uint256 bonus = MAX_TOKEN_AMOUNT_P1_S1_U1 - base;
    IBUILDClaim.ClaimableState memory targetClaimValues = IBUILDClaim.ClaimableState({
      base: base,
      bonus: bonus,
      claimed: 5.5 ether,
      vested: bonus / 2,
      earlyVestableBonus: 2.25 ether,
      loyaltyBonus: 0,
      claimable: 0
    });

    _validateClaimingAmounts(claimingAmounts, targetClaimValues);
  }

  function test_EarlyVestRatios0RegularClaimed() external whenProjectAddedAndClaimDeployed {
    IBUILDFactory.ProjectSeasonConfig memory config = IBUILDFactory.ProjectSeasonConfig({
      tokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      merkleRoot: bytes32(0),
      unlockDelay: UNLOCK_DELAY_P1_S1,
      unlockDuration: UNLOCK_DURATION_S1,
      earlyVestRatioMinBps: 0,
      earlyVestRatioMaxBps: 0,
      baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1,
      isRefunding: false
    });
    IBUILDClaim.GlobalState memory globalState =
      IBUILDClaim.GlobalState({totalLoyalty: 0, totalLoyaltyIneligible: 0, totalClaimed: 0});
    BUILDClaim.UserState memory userState =
      IBUILDClaim.UserState({claimed: 5.5 ether, hasEarlyClaimed: false});
    BUILDClaim.UnlockState memory unlockState = _getUnlockState({
      unlockStartsAt: UNLOCK_START_TIME_S1,
      unlockDelay: UNLOCK_DELAY_P1_S1,
      unlockDuration: UNLOCK_DURATION_S1,
      targetTime: UNLOCK_START_TIME_S1 + UNLOCK_DELAY_P1_S1 + (UNLOCK_DURATION_S1 / 2)
    });
    IBUILDClaim.ClaimableState memory claimingAmounts = _getClaimableState({
      config: config,
      globalState: globalState,
      userState: userState,
      unlockState: unlockState,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1
    });

    uint256 base = BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1 * MAX_TOKEN_AMOUNT_P1_S1_U1
      / PERCENTAGE_BASIS_POINTS_DENOMINATOR;
    uint256 bonus = MAX_TOKEN_AMOUNT_P1_S1_U1 - base;

    IBUILDClaim.ClaimableState memory targetClaimValues = IBUILDClaim.ClaimableState({
      base: base,
      bonus: bonus,
      claimed: 5.5 ether,
      vested: bonus / 2,
      earlyVestableBonus: 0,
      loyaltyBonus: 0,
      claimable: 0
    });

    _validateClaimingAmounts(claimingAmounts, targetClaimValues);
  }
}
