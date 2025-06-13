// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {FixedPointMathLib} from "@solmate/FixedPointMathLib.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDClaim} from "../../src/interfaces/IBUILDClaim.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";
import {Multicall3} from "./../../src/mocks/Multicall3.sol";

/// @notice Requirements
/// [BUS8.1.1](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=34bd38be-3be8-4261-98ca-cf0080662797)
/// [BUS8.1.2](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=910822fb-927e-43d9-9f53-7ff6032a101f)
/// [BUS8.1.3](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=6f5f269a-8b53-410f-a03c-79230f52f28c)
/// [BUS8.1.4](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=09bc1af6-58d6-499f-94de-f19da8edd547)
/// [BUS8.1.5](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=5012db1b-04a3-4024-b5db-e72f007f8277)
/// [BUS8.6](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=ea892cbf-c5b0-4dc3-9349-3f47f470c522)
/// [LEG4.1](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=636e1f3f-b17e-418d-a57e-27d5349822b6)
/// [LEG5](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=cb638911-83a5-40c6-a654-84fe3f1f02f3)
/// [LEG6](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=24e64423-e07c-4645-a5b6-7a3afb65656b)
/// [LEG9](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=57cb08e0-0647-446c-b999-fac41594ed40)
contract BUILDClaimClaimTest is BaseTest {
  modifier whenTheMsgSenderIsTheUserInMerkleProof() {
    _changePrank(USER_1);
    _;
  }

  function test_RevertWhen_TheContractIsPaused()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenClaimPaused(PAUSER, address(s_token))
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
    s_claim.claim(USER_1, params);
  }

  function test_RevertWhen_TheSeasonIsNotConfigured()
    external
    whenProjectAddedAndClaimDeployed
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.SeasonDoesNotExist.selector, SEASON_ID_S1));
    s_claim.claim(USER_1, params);
  }

  function test_RevertWhen_TheProjectSeasonIsNotConfigured()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTheUnlockHasStartedForSeason1
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.ProjectSeasonDoesNotExist.selector, SEASON_ID_S1, address(s_token)
      )
    );
    s_claim.claim(USER_1, params);
  }

  function test_RevertWhen_TheUserProvidedIsZeroAdress()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDClaim.InvalidUser.selector, address(0)));
    s_claim.claim(address(0), params);
  }

  modifier whenTheMsgSenderIsNotTheUserInMerkleProofOrDelegate() {
    _changePrank(USER_2);
    _;
  }

  function test_RevertWhen_TheMsgSenderIsNotTheUserInMerkleProofOrDelegate()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
    whenTheMsgSenderIsNotTheUserInMerkleProofOrDelegate
  {
    uint256 userBalanceBefore = s_token.balanceOf(USER_1);
    uint256 refundableAmount = s_factory.getRefundableAmount(address(s_token), SEASON_ID_S1);
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });

    // it should transfer tokens to the user
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.ProjectSeasonRefundableAmountReduced(
      address(s_token),
      SEASON_ID_S1,
      MAX_TOKEN_AMOUNT_P1_S1_U1,
      refundableAmount - MAX_TOKEN_AMOUNT_P1_S1_U1
    );
    // it should pass as we're not doing early claim
    vm.expectEmit(address(s_claim));
    _emitClaimedNoEarlyClaim(
      USER_1, SEASON_ID_S1, CLAIM_HALF_P1_S1_U1, CLAIM_HALF_P1_S1_U1, CLAIM_HALF_P1_S1_U1
    );
    s_claim.claim(USER_1, params);
    assertEq(s_token.balanceOf(USER_1), userBalanceBefore + CLAIM_HALF_P1_S1_U1);
  }

  function test_WhenTheMsgSenderIsDelegate()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
    whenUserHasDelegated(USER_1, USER_2, address(s_factory))
  {
    uint256 userBalanceBefore = s_token.balanceOf(USER_1);
    uint256 refundableAmount = s_factory.getRefundableAmount(address(s_token), SEASON_ID_S1);
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });

    // it should transfer tokens to the user
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.ProjectSeasonRefundableAmountReduced(
      address(s_token),
      SEASON_ID_S1,
      MAX_TOKEN_AMOUNT_P1_S1_U1,
      refundableAmount - MAX_TOKEN_AMOUNT_P1_S1_U1
    );
    // it should pass as we're not doing early claim
    vm.expectEmit(address(s_claim));
    _emitClaimedNoEarlyClaim(
      USER_1, SEASON_ID_S1, CLAIM_HALF_P1_S1_U1, CLAIM_HALF_P1_S1_U1, CLAIM_HALF_P1_S1_U1
    );
    s_claim.claim(USER_1, params);
    assertEq(s_token.balanceOf(USER_1), userBalanceBefore + CLAIM_HALF_P1_S1_U1);
  }

  function test_RevertWhen_TheSeasonUnlockHasNotStarted()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDClaim.UnlockNotStarted.selector, SEASON_ID_S1));
    s_claim.claim(USER_1, params);
  }

  function test_RevertWhen_TheMerkleProofIsInvalid()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockDelayHasEndedForSeason1
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    bytes32[] memory invalidProof = new bytes32[](1);
    invalidProof[0] = bytes32("");
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: invalidProof,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDClaim.InvalidMerkleProof.selector));
    s_claim.claim(USER_1, params);
  }

  function test_RevertWhen_TheWrongSaltValueIsProvided()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockDelayHasEndedForSeason1
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U2,
      isEarlyClaim: false
    });
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDClaim.InvalidMerkleProof.selector));
    s_claim.claim(USER_1, params);
  }

  function test_RevertWhen_ItsDuringTheUnlockDelay()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockDelayIsActiveForSeason1
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });

    vm.expectRevert(abi.encodeWithSelector(IBUILDClaim.UnlockNotStarted.selector, SEASON_ID_S1));
    s_claim.claim(USER_1, params);
  }

  function test_WhenTheUserHasVestedAmount()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    uint256 userBalanceBefore = s_token.balanceOf(USER_1);
    uint256 refundableAmount = s_factory.getRefundableAmount(address(s_token), SEASON_ID_S1);
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });

    // it should transfer tokens to the user
    // base tokens = 10 tokens * 10% = 1 token
    // unlocked bonus tokens = (10 - 1) tokens * (15 days / 30 days) = 4.5 tokens
    uint256 claimableAmount = 5.5 ether;
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.ProjectSeasonRefundableAmountReduced(
      address(s_token),
      SEASON_ID_S1,
      MAX_TOKEN_AMOUNT_P1_S1_U1,
      refundableAmount - MAX_TOKEN_AMOUNT_P1_S1_U1
    );
    vm.expectEmit(address(s_claim));
    _emitClaimedNoEarlyClaim(
      USER_1, SEASON_ID_S1, claimableAmount, claimableAmount, claimableAmount
    );
    s_claim.claim(USER_1, params);
    assertEq(s_token.balanceOf(USER_1), userBalanceBefore + claimableAmount);
  }

  function test_RevertWhen_TheProjectSeasonStartedRefunding()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
    whenProjectSeasonIsRefunding
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });

    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.ProjectSeasonIsRefunding.selector, address(s_token), SEASON_ID_S1
      )
    );
    s_claim.claim(USER_1, params);
  }

  function test_WhenTheProjectSeasonStartedRefundingAndUserHasClaimed()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
    whenTheUserClaimedTheUnlockedTokens
    whenProjectSeasonIsRefunding
    whenTheUnlockEndedForProject1Season1
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });

    // unlocked bonus tokens = (10 - 1) tokens * (15 days / 30 days) = 4.5 tokens
    uint256 claimableAmount = 4.5 ether;
    uint256 userBalanceBefore = s_token.balanceOf(USER_1);

    // it should transfer the unclaimed tokens to the user (as a regular claim)
    s_claim.claim(USER_1, params);
    assertEq(s_token.balanceOf(USER_1), userBalanceBefore + claimableAmount);
  }

  function test_WhenTheUserHasClaimedAmount()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });

    // first claim (claims base token claim + half of the unlocked bonus tokens)
    // base tokens = 10 tokens * 10% = 1 token
    // unlocked bonus tokens = (10 - 1) tokens * (15 days / 30 days) = 4.5 tokens
    uint256 firstClaimableAmount = 5.5 ether;
    uint256 userBalanceBeforeFirstClaim = s_token.balanceOf(USER_1);
    s_claim.claim(USER_1, params);
    uint256 userBalanceAfterFirstClaim = s_token.balanceOf(USER_1);
    assertEq(userBalanceAfterFirstClaim, userBalanceBeforeFirstClaim + firstClaimableAmount);

    // base token second claim (doesn't claim anything)
    s_claim.claim(USER_1, params);
    assertEq(s_token.balanceOf(USER_1), userBalanceAfterFirstClaim);

    // skip to the end of the unlock period
    skip(UNLOCK_DURATION_S1 / 2 + 1);

    // it should transfer only the unclaimed tokens to the user
    // base tokens = 0 (already claimed)
    // unlocked bonus tokens = (10 - 1) tokens * (15 days / 30 days) = 4.5 tokens
    uint256 secondClaimableAmount = 4.5 ether;
    vm.expectEmit(address(s_claim));
    _emitClaimedNoEarlyClaim(
      USER_1,
      SEASON_ID_S1,
      secondClaimableAmount,
      firstClaimableAmount + secondClaimableAmount,
      firstClaimableAmount + secondClaimableAmount
    );
    s_claim.claim(USER_1, params);
    uint256 userBalanceAfterSecondClaim = s_token.balanceOf(USER_1);
    assertEq(userBalanceAfterSecondClaim, userBalanceAfterFirstClaim + secondClaimableAmount);
  }

  function test_WhenItsAfterTheUnlockDelayAndbaseTokenClaimBpsIsTheMax()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
  {
    _changePrank(ADMIN);
    IBUILDFactory.SetProjectSeasonParams[] memory seasonParams =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    seasonParams[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: TOKEN_AMOUNT_P1_S1,
        baseTokenClaimBps: MAX_BASE_TOKEN_CLAIM_PERCENTAGE,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 1,
        merkleRoot: MERKLE_ROOT_P1_S1,
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S1,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S1,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(seasonParams);

    skip(UNLOCK_START_TIME_S1 + UNLOCK_DELAY_P1_S1 + 1);

    _changePrank(USER_1);
    uint256 userBalanceBefore = s_token.balanceOf(USER_1);
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });

    // it should transfer all of the MAX_TOKEN_AMOUNT_P1_S1_U1 tokens
    s_claim.claim(USER_1, params);
    assertEq(s_token.balanceOf(USER_1), userBalanceBefore + MAX_TOKEN_AMOUNT_P1_S1_U1);
  }

  function test_WhenTheUserAlreadyClaimedAllTokensForTheSeason()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockEndedForProject1Season1
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });

    // claims all unlocked tokens
    s_claim.claim(USER_1, params);
    uint256 userBalanceAfterClaim = s_token.balanceOf(USER_1);

    // it should transfer 0 tokens
    s_claim.claim(USER_1, params);
    assertEq(s_token.balanceOf(USER_1), userBalanceAfterClaim);
  }

  function test_WhenEOAClaimingForMultipleSeasons()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
  {
    _changePrank(ADMIN);

    uint256 unlockStartsAt = uint256(block.timestamp) + UNLOCK_START_TIME_S2;
    s_factory.setSeasonUnlockStartTime(SEASON_ID_S2, unlockStartsAt);

    IBUILDFactory.SetProjectSeasonParams[] memory seasonParams =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    seasonParams[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S2,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: TOKEN_AMOUNT_P1_S2,
        baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P1_S2,
        unlockDelay: UNLOCK_DELAY_P1_S2,
        unlockDuration: UNLOCK_DURATION_S2,
        merkleRoot: MERKLE_ROOT_P1_S2,
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(seasonParams);

    skip(UNLOCK_START_TIME_S2 + UNLOCK_DELAY_P1_S2 + (UNLOCK_DURATION_S2 / 2));
    _changePrank(USER_1);
    uint256 userBalanceBefore = s_token.balanceOf(USER_1);
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](2);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    params[1] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S2,
      proof: MERKLE_PROOF_P1_S2_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S2_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });

    // it should transfer the sum of tokens to the user
    // base tokens = 10 tokens * 10% = 1 token
    // unlocked bonus tokens = (10 - 1) tokens * (30 days / 30 days) = 9 tokens
    uint256 claimableAmountS1 = 10 ether;
    // base tokens = 70 tokens * 15% = 10.5 tokens
    // unlocked bonus tokens = (70 - 10.5) tokens * (30 days / 60 days) = 29.75 tokens
    uint256 claimableAmountS2 = 40.25 ether;
    vm.expectEmit(address(s_claim));
    _emitClaimedNoEarlyClaim(
      USER_1, SEASON_ID_S1, claimableAmountS1, claimableAmountS1, claimableAmountS1
    );
    vm.expectEmit(address(s_claim));
    _emitClaimedNoEarlyClaim(
      USER_1, SEASON_ID_S2, claimableAmountS2, claimableAmountS2, claimableAmountS2
    );
    s_claim.claim(USER_1, params);
    assertEq(s_token.balanceOf(USER_1), userBalanceBefore + claimableAmountS1 + claimableAmountS2);
  }

  function test_WhenEOAClaimingForMultipleProjects()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenProject2AddedAndClaimDeployedAndConfigured
    whenTheUnlockIsInHalfWayForSeason1
  {
    _changePrankTxOrigin(USER_1);

    uint256 userToken1BalanceBefore = s_token.balanceOf(USER_1);
    uint256 userToken2BalanceBefore = s_token_2.balanceOf(USER_1);

    IBUILDClaim.ClaimParams[] memory paramsP1 = new IBUILDClaim.ClaimParams[](1);
    paramsP1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    IBUILDClaim.ClaimParams[] memory paramsP2 = new IBUILDClaim.ClaimParams[](1);
    paramsP2[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P2_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P2_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    Multicall3.Call3[] memory calls = new Multicall3.Call3[](2);
    calls[0] = Multicall3.Call3({
      target: address(s_claim),
      allowFailure: true,
      callData: abi.encodeWithSignature(
        "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])", USER_1, paramsP1
      )
    });
    calls[1] = Multicall3.Call3({
      target: address(s_claim_2),
      allowFailure: true,
      callData: abi.encodeWithSignature(
        "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])", USER_1, paramsP2
      )
    });

    vm.expectEmit(address(s_claim));
    _emitClaimedNoEarlyClaim(
      USER_1, SEASON_ID_S1, CLAIM_HALF_P1_S1_U1, CLAIM_HALF_P1_S1_U1, CLAIM_HALF_P1_S1_U1
    );
    vm.expectEmit(address(s_claim_2));
    _emitClaimedNoEarlyClaim(
      USER_1, SEASON_ID_S1, CLAIM_HALF_P2_S1_U1, CLAIM_HALF_P2_S1_U1, CLAIM_HALF_P2_S1_U1
    );
    Multicall3.Result[] memory returnData = s_multicall.aggregate3(calls);
    assertEq(s_token.balanceOf(USER_1), userToken1BalanceBefore + CLAIM_HALF_P1_S1_U1);
    assertEq(s_token_2.balanceOf(USER_1), userToken2BalanceBefore + CLAIM_HALF_P2_S1_U1);
    assertEq(returnData[0].success, true);
    assertEq(returnData[1].success, true);
  }

  function test_WhenMultisigClaimingForASingleProject()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
  {
    uint256 userBalanceBefore = s_token.balanceOf(USER_MSIG);
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_MSIG,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_MSIG,
      salt: SALT_MSIG,
      isEarlyClaim: false
    });
    assertEq(USER_MSIG, address(s_multisigWallet));
    _changePrankTxOrigin(MSIG_DEPLOYER);

    // it should transfer tokens to the msig contract
    // base tokens = 50 tokens * 10% = 5 token
    // unlocked bonus tokens = (50 - 5) tokens * (15 days / 30 days) = 22.5 tokens
    uint256 claimableAmount = 27.5 ether;
    vm.expectEmit(address(s_claim));
    _emitClaimedNoEarlyClaim(
      USER_MSIG, SEASON_ID_S1, claimableAmount, claimableAmount, claimableAmount
    );
    s_multisigWallet.execTransaction({
      to: address(s_claim),
      data: abi.encodeWithSignature(
        "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])", USER_MSIG, params
      ),
      useDelegateCall: false
    });
    assertEq(s_token.balanceOf(USER_MSIG), userBalanceBefore + claimableAmount);
  }

  function test_WhenMultisigClaimingForMultipleProjects()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenProject2AddedAndClaimDeployedAndConfigured
    whenTheUnlockIsInHalfWayForSeason1
  {
    _changePrankTxOrigin(MSIG_DEPLOYER);
    uint256 userToken1BalanceBefore = s_token.balanceOf(USER_MSIG);
    uint256 userToken2BalanceBefore = s_token_2.balanceOf(USER_MSIG);
    IBUILDClaim.ClaimParams[] memory claimParams1 = new IBUILDClaim.ClaimParams[](1);
    claimParams1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_MSIG,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_MSIG,
      salt: SALT_MSIG,
      isEarlyClaim: false
    });
    IBUILDClaim.ClaimParams[] memory claimParams2 = new IBUILDClaim.ClaimParams[](1);
    claimParams2[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P2_S1_MSIG,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P2_S1_MSIG,
      salt: SALT_MSIG,
      isEarlyClaim: false
    });

    // it should transfer the tokens from each project to the msig contract
    // base tokens = 50 tokens * 10% = 5 token
    // unlocked bonus tokens = (50 - 5) tokens * (15 days / 30 days) = 22.5 tokens
    uint256 claimableAmountP1 = 27.5 ether;
    // base tokens = 100 tokens * 5% = 5 tokens
    // unlocked bonus tokens = (100 - 5) tokens * (17 days / 30 days) = 53.833333 tokens
    uint256 claimableAmountP2 = 58833333;

    bytes memory data1 = abi.encodeWithSignature(
      "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])", USER_MSIG, claimParams1
    );
    bytes memory data2 = abi.encodeWithSignature(
      "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])", USER_MSIG, claimParams2
    );

    vm.expectEmit(address(s_claim));
    _emitClaimedNoEarlyClaim(
      USER_MSIG, SEASON_ID_S1, claimableAmountP1, claimableAmountP1, claimableAmountP1
    );
    vm.expectEmit(address(s_claim_2));
    _emitClaimedNoEarlyClaim(
      USER_MSIG, SEASON_ID_S1, claimableAmountP2, claimableAmountP2, claimableAmountP2
    );

    s_multisigWallet.execTransaction({
      to: address(s_multiSendCallOnly),
      data: abi.encodeWithSignature(
        "multiSend(bytes)",
        bytes.concat(
          abi.encodePacked(
            uint8(0), // operation type (0 = call, 1 = delegatecall)
            address(s_claim), // to
            uint256(0), // value
            uint256(data1.length),
            data1
          ),
          abi.encodePacked(
            uint8(0), // operation type (0 = call, 1 = delegatecall)
            address(s_claim_2), // to
            uint256(0), // value
            uint256(data2.length),
            data2
          )
        )
      ),
      useDelegateCall: true
    });
    assertEq(s_token.balanceOf(USER_MSIG), userToken1BalanceBefore + claimableAmountP1);
    assertEq(s_token_2.balanceOf(USER_MSIG), userToken2BalanceBefore + claimableAmountP2);
  }

  function test_RevertWhen_TheTokenTriesToReenter()
    external
    whenReentrantProjectAddedAndClaimDeployed
    whenASeasonConfigIsSetForTheSeason
  {
    address projectAdmin = address(s_token_reentrant);
    _changePrank(projectAdmin);
    s_token_reentrant.disableReentrancy();
    s_claim_reentrant.deposit(TOKEN_AMOUNT_P1_S1);

    _changePrank(ADMIN);
    IBUILDFactory.SetProjectSeasonParams[] memory seasonParams =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    seasonParams[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token_reentrant),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: TOKEN_AMOUNT_P1_S1,
        baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1,
        unlockDelay: 0,
        unlockDuration: UNLOCK_DURATION_S1,
        merkleRoot: MERKLE_ROOT_P1_S1,
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S1,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S1,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(seasonParams);
    skip(UNLOCK_START_TIME_S1 + 1);

    _changePrank(USER_1);
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    bytes memory data = abi.encodeWithSelector(IBUILDClaim.claim.selector, USER_1, params);
    s_token_reentrant.enableRentrancy(address(s_claim_reentrant), data);

    // it should revert
    vm.expectRevert(abi.encodeWithSelector(ReentrancyGuard.ReentrancyGuardReentrantCall.selector));
    s_claim_reentrant.claim(USER_1, params);
  }
  // TODO test different earlyVestRatioMinBps and earlyVestRatioMaxBps percentages
  // TODO test invalid EARLY_VEST_RATIO_MIN and earlyVestRatioMaxBps percentages, ie doesn't equal
  // 100%.

  function test_RevertWhen_EarlyClaimTheContractIsPaused()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenClaimPaused(PAUSER, address(s_token))
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
    s_claim.claim(USER_1, params_U1);
  }

  function test_RevertWhen_EarlyClaimTheSeasonIsNotConfigured()
    external
    whenProjectAddedAndClaimDeployed
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.SeasonDoesNotExist.selector, SEASON_ID_S1));
    s_claim.claim(USER_1, params_U1);
  }

  function test_RevertWhen_EarlyClaimTheProjectSeasonIsNotConfigured()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTheUnlockHasStartedForSeason1
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.ProjectSeasonDoesNotExist.selector, SEASON_ID_S1, address(s_token)
      )
    );
    s_claim.claim(USER_1, params_U1);
  }

  function test_RevertWhen_EarlyClaimTheUserProvidedIsZeroAdress()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDClaim.InvalidUser.selector, address(0)));
    s_claim.claim(address(0), params_U1);
  }

  function test_RevertWhen_EarlyClaimTheMsgSenderIsNotTheUserInMerkleProofOrDelegate()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
    whenTheMsgSenderIsNotTheUserInMerkleProofOrDelegate
  {
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDClaim.InvalidSender.selector, USER_2));
    s_claim.claim(USER_1, params_U1);
  }

  function test_WhenEarlyClaimTheMsgSenderIsDelegate()
    external
    whenSeason1IsSetup
    whenSeason2IsSetup
    whenTheUnlockDelayHasEndedForSeason2
    whenUserHasDelegated(USER_1, USER_2, address(s_factory))
  {
    uint256 user1BalanceBefore = s_token.balanceOf(USER_1);
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](2);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    params_U1[1] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S2,
      proof: MERKLE_PROOF_P1_S2_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S2_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });
    // it should transfer tokens to the user
    // base tokens = 10 tokens * 10% = 1 token
    // unlocked bonus tokens = (10 - 1) tokens * (23 days / 30 days) = 6.9 tokens
    uint256 claimableAmountS1 = 7.9 ether;
    vm.expectEmit(address(s_claim));
    _emitClaimedNoEarlyClaim(
      USER_1, SEASON_ID_S1, claimableAmountS1, claimableAmountS1, claimableAmountS1
    );
    vm.expectEmit(address(s_claim));
    emit IBUILDClaim.Claimed(
      USER_1,
      SEASON_ID_S2,
      EARLY_CLAIM_START_P1_S2_U1,
      true,
      EARLY_CLAIM_START_P1_S2_U1 - CLAIM_START_P1_S2_U1,
      EARLY_CLAIM_START_P1_S2_U1,
      EARLY_CLAIM_START_P1_S2_U1,
      MAX_TOKEN_AMOUNT_P1_S2_U1 - EARLY_CLAIM_START_P1_S2_U1,
      MAX_TOKEN_AMOUNT_P1_S2_U1
    );
    s_claim.claim(USER_1, params_U1);
    assertEq(
      s_token.balanceOf(USER_1), user1BalanceBefore + claimableAmountS1 + EARLY_CLAIM_START_P1_S2_U1
    );
  }

  function test_RevertWhen_EarlyClaimTheSeasonUnlockHasNotStarted()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDClaim.UnlockNotStarted.selector, SEASON_ID_S1));
    s_claim.claim(USER_1, params_U1);
  }

  function test_RevertWhen_EarlyClaimTheMerkleProofIsInvalid()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockDelayHasEndedForSeason1
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    bytes32[] memory invalidProof = new bytes32[](1);
    invalidProof[0] = bytes32("");
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: invalidProof,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDClaim.InvalidMerkleProof.selector));
    s_claim.claim(USER_1, params_U1);
  }

  function test_EarlyClaimWhenItsDuringTheUnlockDelay()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockDelayIsActiveForSeason1
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });

    vm.expectRevert(abi.encodeWithSelector(IBUILDClaim.UnlockNotStarted.selector, SEASON_ID_S1));
    s_claim.claim(USER_1, params_U1);
  }

  // function test_WhenTheUserHasVestedAmount()
  //   external
  //   whenASeasonConfigIsSetForTheSeason
  //   whenProjectAddedAndClaimDeployed
  //   whenTokensAreDepositedForTheProject
  //   whenASeasonConfigIsSetForTheProject
  //   whenTheUnlockIsInHalfWayForSeason1
  //   whenTheMsgSenderIsTheUserInMerkleProof
  // {
  //   uint256 user1BalanceBefore = s_token.balanceOf(USER_1);
  //   IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
  //   params_U1[0] = IBUILDClaim.ClaimParams({
  //     seasonId: SEASON_ID_S1,
  //     proof: MERKLE_PROOF_P1_S1_U1,
  //     maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
  //     salt: SALT_U1,
  //     isEarlyClaim: true
  //   });

  //   // it should transfer tokens to the user
  //   // base tokens = 10 tokens * 10% = 1 token
  //   // unlocked bonus tokens = (10 - 1) tokens * (15 days / 30 days) = 4.5 tokens
  //   uint256 claimableAmount = 5.5 ether;
  //   vm.expectEmit(address(s_claim));
  //   _emitClaimedNoEarlyClaim(
  //     USER_1, SEASON_ID_S1, claimableAmount, claimableAmount, claimableAmount
  //   );
  //   s_claim.claim(USER_1, params_U1);
  //   assertEq(s_token.balanceOf(USER_1), user1BalanceBefore + claimableAmount);
  // }

  function test_RevertWhen_EarlyClaimTheProjectSeasonStartedRefunding()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
    whenProjectSeasonIsRefunding
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });

    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.ProjectSeasonIsRefunding.selector, address(s_token), SEASON_ID_S1
      )
    );
    s_claim.claim(USER_1, params_U1);
  }

  function test_WhenEarlyClaimTheProjectSeasonStartedRefundingAndUserHasClaimed()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
    whenTheUserClaimedTheUnlockedTokens
    whenProjectSeasonIsRefunding
    whenTheUnlockEndedForProject1Season1
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });

    // unlocked bonus tokens = (10 - 1) tokens * (15 days / 30 days) = 4.5 tokens
    uint256 claimableAmount = 4.5 ether;
    uint256 user1BalanceBefore = s_token.balanceOf(USER_1);

    // it should transfer the unclaimed tokens to the user (as a regular claim)
    s_claim.claim(USER_1, params_U1);
    assertEq(s_token.balanceOf(USER_1), user1BalanceBefore + claimableAmount);
  }

  function test_EarlyClaimWhenTheUserHasClaimedAmount()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });

    // first claim (claims base token claim + half of the unlocked bonus tokens)
    // base tokens = 10 tokens * 10% = 1 token
    // unlocked bonus tokens = (10 - 1) tokens * (15 days / 30 days) = 4.5 tokens
    uint256 firstClaimableAmount = 5.5 ether;
    uint256 user1BalanceBeforeFirstClaim = s_token.balanceOf(USER_1);
    s_claim.claim(USER_1, params_U1);
    uint256 userBalanceAfterFirstClaim = s_token.balanceOf(USER_1);
    assertEq(userBalanceAfterFirstClaim, user1BalanceBeforeFirstClaim + firstClaimableAmount);

    // base token second claim (doesn't claim anything)
    s_claim.claim(USER_1, params_U1);
    assertEq(s_token.balanceOf(USER_1), userBalanceAfterFirstClaim);

    // skip to the 5/6 period of the unlock
    skip(UNLOCK_DURATION_S1 / 3);

    // it should transfer only the unclaimed tokens to the user
    // base tokens = 0 (already claimed)
    // unlocked bonus tokens = (10 - 1) tokens * (10 days / 30 days) = 3.0 tokens
    // early vest will be 1.5 tokens * 10 + ((90 - 10) * 5/6) = 10 + (80 * 5/6) = 10 + 66.67 = 1.5 *
    // .2333 = 0.35 tokens
    // will be able to claim 3.0 + (1.5 - .35) = 4.15 tokens for a total of 9.65 tokens.

    // NOTE: There is a tiny rounding that happens because the 5/6 is not exact, and is rounded
    // down, so the claimable amount is 4.1499999999999.. ether.
    uint256 earlyClaimAmount = 1.15 ether - 1;
    uint256 secondClaimableAmount = 3 ether + earlyClaimAmount;
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });
    vm.expectEmit(address(s_claim));
    emit IBUILDClaim.Claimed(
      USER_1,
      SEASON_ID_S1,
      secondClaimableAmount,
      true,
      earlyClaimAmount,
      firstClaimableAmount + secondClaimableAmount,
      firstClaimableAmount + secondClaimableAmount,
      MAX_TOKEN_AMOUNT_P1_S1_U1 - firstClaimableAmount - secondClaimableAmount,
      MAX_TOKEN_AMOUNT_P1_S1_U1
    );
    s_claim.claim(USER_1, params_U1);
    uint256 userBalanceAfterSecondClaim = s_token.balanceOf(USER_1);
    assertEq(userBalanceAfterSecondClaim, userBalanceAfterFirstClaim + secondClaimableAmount);
  }

  function test_EarlyClaimWhenTheUserHasAlreadyEarlyClaimed()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });

    s_claim.claim(USER_1, params_U1);
    uint256 userBalanceAfterFirstClaim = s_token.balanceOf(USER_1);

    // skip to the 5/6 period of the unlock
    // reverts for second attempted early claim
    skip(UNLOCK_DURATION_S1 / 3);
    vm.expectRevert(
      abi.encodeWithSelector(IBUILDClaim.InvalidEarlyClaim.selector, USER_1, SEASON_ID_S1)
    );
    s_claim.claim(USER_1, params_U1);
    uint256 userBalanceAfterSecondClaim = s_token.balanceOf(USER_1);
    assertEq(userBalanceAfterSecondClaim, userBalanceAfterFirstClaim);
  }

  function test_EarlyClaimWhenItsHalfwayIntoUnlock()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
  {
    uint40 unlockDuration = 2;
    _changePrank(ADMIN);
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: TOKEN_AMOUNT_P1_S1,
        baseTokenClaimBps: MAX_BASE_TOKEN_CLAIM_PERCENTAGE / 2,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: unlockDuration,
        merkleRoot: MERKLE_ROOT_P1_S1,
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S1,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S1,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);

    uint256 halfwayIntoUnlock = UNLOCK_START_TIME_S1 + UNLOCK_DELAY_P1_S1 + unlockDuration / 2;
    skip(halfwayIntoUnlock);

    _changePrank(USER_1);
    uint256 user1BalanceBefore = s_token.balanceOf(USER_1);
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });

    // it should transfer all of the MAX_TOKEN_AMOUNT_P1_S1_U1 tokens
    s_claim.claim(USER_1, params_U1);
    uint256 claimedAmountShouldBe = user1BalanceBefore + MAX_TOKEN_AMOUNT_P1_S1_U1 * 8750 / 10000;
    assertEq(s_token.balanceOf(USER_1), claimedAmountShouldBe);
  }

  function test_EarlyClaimClaimHalfwayIntoUnlockAndClaimsAfterVestIncludingAll()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
  {
    uint40 unlockDuration = 2;
    _changePrank(ADMIN);
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: TOKEN_AMOUNT_P1_S1,
        baseTokenClaimBps: MAX_BASE_TOKEN_CLAIM_PERCENTAGE / 2,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: unlockDuration,
        merkleRoot: MERKLE_ROOT_P1_S1,
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S1,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S1,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);

    uint256 halfwayIntoUnlock = UNLOCK_START_TIME_S1 + UNLOCK_DELAY_P1_S1 + unlockDuration / 2;
    skip(halfwayIntoUnlock);

    _changePrank(USER_1);
    uint256 user1BalanceBefore = s_token.balanceOf(USER_1);
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });

    // it should transfer 87.5% of the MAX_TOKEN_AMOUNT_P1_S1_U1 tokens
    // base token claim 50%, 25% unlocked, 25% available for early vest and early vest ratio is 50%
    s_claim.claim(USER_1, params_U1);
    uint256 claimedAmountShouldBe = user1BalanceBefore + MAX_TOKEN_AMOUNT_P1_S1_U1 * 8750 / 10000;
    assertEq(s_token.balanceOf(USER_1), claimedAmountShouldBe);

    // skip past the unlock period
    skip(unlockDuration);
    _changePrank(USER_2);
    uint256 user2BalanceBefore = s_token.balanceOf(USER_2);
    IBUILDClaim.ClaimParams[] memory params_U2 = new IBUILDClaim.ClaimParams[](1);
    params_U2[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U2,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U2,
      salt: SALT_U2,
      isEarlyClaim: false
    });

    // it should transfer 100% of the MAX_TOKEN_AMOUNT_P1_S1_U2 tokens
    // and the loyalty tokens from the previous claim.
    s_claim.claim(USER_2, params_U2);

    // total amount is 150 ether. U1 = 10 ether, U2 = 90 ether, M1 = 50 ether.
    // U2 should get 90/140 of loyalty.
    // M1 should get 50/140 of loyalty.
    // loyalty is 1.25 ether
    uint256 claimedAmountShouldBe2 = user2BalanceBefore + MAX_TOKEN_AMOUNT_P1_S1_U2
      + 1250 * MAX_TOKEN_AMOUNT_P1_S1_U1 * 90 / 140 / 10000;
    assertEq(s_token.balanceOf(USER_2), claimedAmountShouldBe2);

    _changePrank(USER_MSIG);
    uint256 userMBalanceBefore = s_token.balanceOf(USER_MSIG);
    IBUILDClaim.ClaimParams[] memory params_MSIG = new IBUILDClaim.ClaimParams[](1);
    params_MSIG[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_MSIG,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_MSIG,
      salt: SALT_MSIG,
      isEarlyClaim: false
    });

    // it should transfer 100% of the MAX_TOKEN_AMOUNT_P1_S1_U2 tokens
    // and the loyalty tokens from the previous claim.
    s_claim.claim(USER_MSIG, params_MSIG);

    // total amount is 150 ether. U1 = 10 ether, U2 = 90 ether, M1 = 50 ether.
    // U2 should get 90/140 of loyalty.
    // M1 should get 50/140 of loyalty.
    // loyalty is 1.25 ether
    uint256 claimedAmountShouldBeMSIG = userMBalanceBefore + MAX_TOKEN_AMOUNT_P1_S1_MSIG
      + 1250 * MAX_TOKEN_AMOUNT_P1_S1_U1 * 50 / 140 / 10000;
    assertEq(s_token.balanceOf(USER_MSIG), claimedAmountShouldBeMSIG);
  }

  function test_EarlyClaimWhenTheUserAlreadyClaimedAllTokensForTheSeason()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    // whenTheUnlockEndedForProject1Season1
    whenTheMsgSenderIsTheUserInMerkleProof
  {
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });

    skip(UNLOCK_START_TIME_S1 + UNLOCK_DELAY_P1_S1);

    // claims all unlocked + early vest tokens
    s_claim.claim(USER_1, params_U1);
    skip(UNLOCK_DURATION_S1 + 1);

    // early claim after unlock duration is processed as normal
    // 0 tokens transferred
    s_claim.claim(USER_1, params_U1);

    uint256 baseTokenAmount = MAX_TOKEN_AMOUNT_P1_S1_U1 * BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1 / 10000;
    uint256 bonusTokenAmount = MAX_TOKEN_AMOUNT_P1_S1_U1 - baseTokenAmount;
    uint256 earlyVestBonusTokenAmount =
      FixedPointMathLib.mulDivDown(bonusTokenAmount, EARLY_VEST_RATIO_MIN_P1_S1, 10000);
    assertEq(s_token.balanceOf(USER_1), baseTokenAmount + earlyVestBonusTokenAmount);
  }

  function test_EarlyClaimWhenEOAClaimingForMultipleSeasons()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
  {
    _changePrank(ADMIN);

    uint256 unlockStartsAt = uint256(block.timestamp) + UNLOCK_START_TIME_S2;
    s_factory.setSeasonUnlockStartTime(SEASON_ID_S2, unlockStartsAt);

    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S2,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: TOKEN_AMOUNT_P1_S2,
        baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P1_S2,
        unlockDelay: UNLOCK_DELAY_P1_S2,
        unlockDuration: UNLOCK_DURATION_S2,
        merkleRoot: MERKLE_ROOT_P1_S2,
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S1,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S1,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);

    skip(UNLOCK_START_TIME_S2 + UNLOCK_DELAY_P1_S2 + (UNLOCK_DURATION_S2 / 2));
    _changePrank(USER_1);
    uint256 user1BalanceBefore = s_token.balanceOf(USER_1);
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](2);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    params_U1[1] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S2,
      proof: MERKLE_PROOF_P1_S2_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S2_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });

    // it should transfer the sum of tokens to the user
    // base tokens = 10 tokens * 10% = 1 token
    // unlocked bonus tokens = (10 - 1) tokens * (30 days / 30 days) = 9 tokens
    uint256 claimableAmountS1 = 10 ether;
    // base tokens = 70 tokens * 15% = 10.5 tokens
    // unlocked bonus tokens = (70 - 10.5) tokens * (30 days / 60 days) = 29.75 tokens
    // early vest ratio = 29.75 tokens * 10 + ((90 - 10) * 30/60) = 10 + (80 * 30/60) = 10 + 40 =
    // 1/2 * 29.75
    // =
    // 14.875
    // will be able to claim 10.5 + 29.75 + 14.875 tokens for a total of 55.125 tokens.
    uint256 claimableAmountS2 = 55.125 ether;
    uint256 regularClaimS2 = 10.5 ether + 29.75 ether;
    vm.expectEmit(address(s_claim));
    _emitClaimedNoEarlyClaim(
      USER_1, SEASON_ID_S1, claimableAmountS1, claimableAmountS1, claimableAmountS1
    );
    vm.expectEmit(address(s_claim));
    emit IBUILDClaim.Claimed(
      USER_1,
      SEASON_ID_S2,
      claimableAmountS2,
      true,
      claimableAmountS2 - regularClaimS2,
      claimableAmountS2,
      claimableAmountS2,
      MAX_TOKEN_AMOUNT_P1_S2_U1 - claimableAmountS2,
      MAX_TOKEN_AMOUNT_P1_S2_U1
    );
    s_claim.claim(USER_1, params_U1);
    assertEq(s_token.balanceOf(USER_1), user1BalanceBefore + claimableAmountS1 + claimableAmountS2);
  }

  function test_EarlyClaimWhenEOAClaimingForMultipleProjects()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenProject2AddedAndClaimDeployedAndConfigured
    whenTheUnlockIsInHalfWayForSeason1
  {
    _changePrankTxOrigin(USER_1);

    uint256 userToken1BalanceBefore = s_token.balanceOf(USER_1);
    uint256 userToken2BalanceBefore = s_token_2.balanceOf(USER_1);

    IBUILDClaim.ClaimParams[] memory paramsP1 = new IBUILDClaim.ClaimParams[](1);
    paramsP1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });
    IBUILDClaim.ClaimParams[] memory paramsP2 = new IBUILDClaim.ClaimParams[](1);
    paramsP2[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P2_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P2_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });
    Multicall3.Call3[] memory calls = new Multicall3.Call3[](2);
    calls[0] = Multicall3.Call3({
      target: address(s_claim),
      allowFailure: true,
      callData: abi.encodeWithSignature(
        "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])", USER_1, paramsP1
      )
    });
    calls[1] = Multicall3.Call3({
      target: address(s_claim_2),
      allowFailure: true,
      callData: abi.encodeWithSignature(
        "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])", USER_1, paramsP2
      )
    });

    // it should fail and not transfer any tokens
    Multicall3.Result[] memory returnData = s_multicall.aggregate3(calls);
    assertEq(s_token.balanceOf(USER_1), userToken1BalanceBefore);
    assertEq(s_token_2.balanceOf(USER_1), userToken2BalanceBefore);
    assertEq(returnData[0].success, false);
    assertEq(returnData[1].success, false);
  }

  function test_EarlyClaimWhenMultisigClaimingForASingleProject()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheUnlockIsInHalfWayForSeason1
  {
    uint256 user1BalanceBefore = s_token.balanceOf(USER_MSIG);
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_MSIG_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_MSIG,
      salt: SALT_MSIG,
      isEarlyClaim: true
    });
    assertEq(USER_MSIG, address(s_multisigWallet));
    _changePrankTxOrigin(MSIG_DEPLOYER);

    // it should transfer tokens to the msig contract
    // base tokens = 50 tokens * 10% = 5 token
    // unlocked bonus tokens = (50 - 5) tokens * (15 days / 30 days) = 22.5 tokens
    // can early claim another 1/2 22.5 = 11.25 tokens
    // will be able to claim 5 + 22.5 + 11.25 tokens for a total of 38.75 tokens.
    vm.expectEmit(address(s_claim));
    emit IBUILDClaim.Claimed(
      USER_MSIG,
      SEASON_ID_S1,
      EARLY_CLAIM_HALF_P1_S1_MSIG,
      true,
      EARLY_CLAIM_HALF_P1_S1_MSIG - CLAIM_HALF_P1_S1_MSIG,
      EARLY_CLAIM_HALF_P1_S1_MSIG,
      EARLY_CLAIM_HALF_P1_S1_MSIG,
      MAX_TOKEN_AMOUNT_P1_S1_MSIG - EARLY_CLAIM_HALF_P1_S1_MSIG,
      MAX_TOKEN_AMOUNT_P1_S1_MSIG
    );
    s_multisigWallet.execTransaction({
      to: address(s_claim),
      data: abi.encodeWithSignature(
        "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])", USER_MSIG, params_U1
      ),
      useDelegateCall: false
    });
    assertEq(s_token.balanceOf(USER_MSIG), user1BalanceBefore + EARLY_CLAIM_HALF_P1_S1_MSIG);
  }

  function test_EarlyClaimWhenMultisigClaimingForMultipleProjects()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenProject2AddedAndClaimDeployedAndConfigured
    whenTheUnlockIsInHalfWayForSeason1
  {
    _changePrankTxOrigin(MSIG_DEPLOYER);
    uint256 userToken1BalanceBefore = s_token.balanceOf(USER_MSIG);
    uint256 userToken2BalanceBefore = s_token_2.balanceOf(USER_MSIG);
    IBUILDClaim.ClaimParams[] memory claimParams1 = new IBUILDClaim.ClaimParams[](1);
    claimParams1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_MSIG_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_MSIG,
      salt: SALT_MSIG,
      isEarlyClaim: true
    });
    IBUILDClaim.ClaimParams[] memory claimparams_U2 = new IBUILDClaim.ClaimParams[](1);
    claimparams_U2[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P2_S1_MSIG_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P2_S1_MSIG,
      salt: SALT_MSIG,
      isEarlyClaim: true
    });

    // it should transfer the tokens from each project to the msig contract
    // base tokens = 50 tokens * 10% = 5 token
    // unlocked bonus tokens = (50 - 5) tokens * (15 days / 30 days) = 22.5 tokens
    // early claim amount = (50 - 5) tokens * (15 days / 30 days) = 22.5 tokens
    // early vest = 22.5 tokens * 10 + ((90 - 10) * 15/30) = 10 + (80 * 15/30) = 10 + 40
    // = 1/2 * 22.5 = 11.25
    // will be able to claim 5 + 22.5 + 11.25 tokens for a total of 38.75 tokens.
    bytes memory data1 = abi.encodeWithSignature(
      "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])", USER_MSIG, claimParams1
    );
    // base tokens = 100 tokens * 5% = 5 tokens
    // unlocked bonus tokens = (100 - 5) tokens * (17 days / 30 days) = 53.833333 tokens
    // early claim amount = (100 - 5) tokens * (13 days / 30 days) = 41.166667 tokens
    // early vest = 41.166667 tokens * 10 + ((90 - 10) * 17/30) =  41.166667 * (10 + (80 * 17/30)) =
    // 41.166667 * (90 - 45.33) = 41.166667 * .44666667 =
    // 18.3877777
    // will be able to claim 5 + 53.833333 + (41.166667 - 18.38777) tokens = 81.6122222222 tokens.
    uint256 claimableAmountP2 = 81612222;
    uint256 regularClaimP2 = 5000000 + 53833333;
    bytes memory data2 = abi.encodeWithSignature(
      "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])", USER_MSIG, claimparams_U2
    );

    vm.expectEmit(address(s_claim));
    emit IBUILDClaim.Claimed(
      USER_MSIG,
      SEASON_ID_S1,
      EARLY_CLAIM_HALF_P1_S1_MSIG,
      true,
      EARLY_CLAIM_HALF_P1_S1_MSIG - CLAIM_HALF_P1_S1_MSIG,
      EARLY_CLAIM_HALF_P1_S1_MSIG,
      EARLY_CLAIM_HALF_P1_S1_MSIG,
      MAX_TOKEN_AMOUNT_P1_S1_MSIG - EARLY_CLAIM_HALF_P1_S1_MSIG,
      MAX_TOKEN_AMOUNT_P1_S1_MSIG
    );
    vm.expectEmit(address(s_claim_2));
    emit IBUILDClaim.Claimed(
      USER_MSIG,
      SEASON_ID_S1,
      claimableAmountP2,
      true,
      claimableAmountP2 - regularClaimP2,
      claimableAmountP2,
      claimableAmountP2,
      MAX_TOKEN_AMOUNT_P2_S1_MSIG - claimableAmountP2,
      MAX_TOKEN_AMOUNT_P2_S1_MSIG
    );

    s_multisigWallet.execTransaction({
      to: address(s_multiSendCallOnly),
      data: abi.encodeWithSignature(
        "multiSend(bytes)",
        bytes.concat(
          abi.encodePacked(
            uint8(0), // operation type (0 = call, 1 = delegatecall)
            address(s_claim), // to
            uint256(0), // value
            uint256(data1.length),
            data1
          ),
          abi.encodePacked(
            uint8(0), // operation type (0 = call, 1 = delegatecall)
            address(s_claim_2), // to
            uint256(0), // value
            uint256(data2.length),
            data2
          )
        )
      ),
      useDelegateCall: true
    });
    assertEq(s_token.balanceOf(USER_MSIG), userToken1BalanceBefore + EARLY_CLAIM_HALF_P1_S1_MSIG);
    assertEq(s_token_2.balanceOf(USER_MSIG), userToken2BalanceBefore + claimableAmountP2);
  }

  function test_RevertWhen_EarlyClaimTheTokenTriesToReenter()
    external
    whenReentrantProjectAddedAndClaimDeployed
    whenASeasonConfigIsSetForTheSeason
  {
    address projectAdmin = address(s_token_reentrant);
    _changePrank(projectAdmin);
    s_token_reentrant.disableReentrancy();
    s_claim_reentrant.deposit(TOKEN_AMOUNT_P1_S1);

    _changePrank(ADMIN);
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token_reentrant),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: TOKEN_AMOUNT_P1_S1,
        baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1,
        unlockDelay: 0,
        unlockDuration: UNLOCK_DURATION_S1,
        merkleRoot: MERKLE_ROOT_P1_S1,
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S1,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S1,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);
    skip(UNLOCK_START_TIME_S1 + 1);

    _changePrank(USER_1);
    IBUILDClaim.ClaimParams[] memory params_U1 = new IBUILDClaim.ClaimParams[](1);
    params_U1[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });
    bytes memory data = abi.encodeWithSelector(IBUILDClaim.claim.selector, USER_1, params_U1);
    s_token_reentrant.enableRentrancy(address(s_claim_reentrant), data);

    vm.expectRevert(abi.encodeWithSelector(ReentrancyGuard.ReentrancyGuardReentrantCall.selector));
    s_claim_reentrant.claim(USER_1, params_U1);
  }
}
