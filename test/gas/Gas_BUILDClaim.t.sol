// SPDX-License-Identifier: MIT
/* solhint-disable one-contract-per-file */
pragma solidity 0.8.26;

import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDClaim} from "../../src/interfaces/IBUILDClaim.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";
import {Multicall3} from "./../../src/mocks/Multicall3.sol";

abstract contract Gas_BUILDClaim_Base is BaseTest {
  function setUp()
    public
    virtual
    whenProjectAddedAndClaimDeployed
    whenASeasonConfigIsSetForTheSeason
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenProject2AddedAndClaimDeployedAndConfigured
    whenTheUnlockIsInHalfWayForSeason1
  {}
}

contract Gas_BUILDClaim_Claim_SingleProjectSingleSeason is Gas_BUILDClaim_Base {
  function setUp() public override {
    Gas_BUILDClaim_Base.setUp();

    _changePrank(USER_1);
  }

  function test_Gas_Claim() external {
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    s_claim.claim(USER_1, params);
  }

  function test_Gas_Deposit() external {}
}

contract Gas_BUILDClaim_Claim_SingleProjectMultipleSeasons is Gas_BUILDClaim_Base {
  function setUp() public override {
    Gas_BUILDClaim_Base.setUp();

    _changePrank(ADMIN);
    uint40 unlockStartsAt = uint40(block.timestamp) + UNLOCK_START_TIME_S2;
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
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);
    skip(UNLOCK_START_TIME_S2 + UNLOCK_DELAY_P2_S1 + UNLOCK_DURATION_S2 / 2);

    _changePrank(USER_1);
  }

  function test_Gas_Claim() external {
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
    s_claim.claim(USER_1, params);
  }
}

contract Gas_BUILDClaim_Claim_MultipleProjectsSingleSeasonEach is Gas_BUILDClaim_Base {
  function setUp() public override {
    Gas_BUILDClaim_Base.setUp();

    _changePrankTxOrigin(USER_1);
  }

  function test_Gas_Claim() external {
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    Multicall3.Call3[] memory calls = new Multicall3.Call3[](2);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    calls[0] = Multicall3.Call3({
      target: address(s_claim),
      allowFailure: true,
      callData: abi.encodeWithSignature(
        "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])", USER_1, params
      )
    });
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P2_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P2_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    calls[1] = Multicall3.Call3({
      target: address(s_claim_2),
      allowFailure: true,
      callData: abi.encodeWithSignature(
        "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])", USER_1, params
      )
    });
    s_multicall.aggregate3(calls);
  }
}

contract Gas_BUILDClaim_Claim_MultipleProjectsMultipleSeasons is Gas_BUILDClaim_Base {
  function setUp() public override {
    Gas_BUILDClaim_Base.setUp();

    _changePrank(PROJECT_ADMIN);
    s_token_2.approve(address(s_claim_2), TOKEN_AMOUNT_P2_S1);
    s_claim_2.deposit(TOKEN_AMOUNT_P2_S1);

    _changePrank(ADMIN);
    uint40 unlockStartsAt = uint40(block.timestamp) + UNLOCK_START_TIME_S2;
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
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token_2),
      seasonId: SEASON_ID_S2,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: TOKEN_AMOUNT_P2_S1,
        baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P2_S1,
        unlockDelay: UNLOCK_DELAY_P2_S1,
        unlockDuration: UNLOCK_DURATION_S2,
        merkleRoot: MERKLE_ROOT_P2_S1,
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S1,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S1,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);
    skip(UNLOCK_START_TIME_S2 + UNLOCK_DELAY_P2_S1 + UNLOCK_DURATION_S2 / 2);

    _changePrankTxOrigin(USER_1);
  }

  function test_Gas_Claim() external {
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](2);
    Multicall3.Call3[] memory calls = new Multicall3.Call3[](2);
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
    calls[0] = Multicall3.Call3({
      target: address(s_claim),
      allowFailure: true,
      callData: abi.encodeWithSignature(
        "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])", USER_1, params
      )
    });

    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P2_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P2_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    params[1] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S2,
      proof: MERKLE_PROOF_P2_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P2_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    calls[1] = Multicall3.Call3({
      target: address(s_claim_2),
      allowFailure: true,
      callData: abi.encodeWithSignature(
        "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])", USER_1, params
      )
    });

    s_multicall.aggregate3(calls);
  }
}

contract Gas_BUILDClaim_Deposit is Gas_BUILDClaim_Base {
  function setUp() public override {
    Gas_BUILDClaim_Base.setUp();

    _changePrank(PROJECT_ADMIN);
  }

  function test_Gas_Deposit() external {
    s_token.approve(address(s_claim), TOKEN_AMOUNT_P1_S1);
    s_claim.deposit(TOKEN_AMOUNT_P1_S1);
  }
}
