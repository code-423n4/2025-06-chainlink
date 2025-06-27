pragma solidity 0.8.26;

import {BaseTest} from "./BaseTest.t.sol";
import {Constants} from "./Constants.t.sol";
import "src/BUILDClaim.sol";
import "src/BUILDFactory.sol";
import {console} from "forge-std/Script.sol";

contract PoC is BaseTest {
  uint256 public constant POC_USER_EARLY_CLAIM_MAX_TOKEN_AMOUNT = 500e2;
  uint256 public constant POC_USER_SMALL_REWARD_MAX_TOKEN_AMOUNT = 10e2;
  uint256 public constant POC_USERS_WITH_SMALL_REWARDS_POOL_SIZE = 50_000;
  uint256 public constant POC_TOKEN_AMOUNT_P1_S1 = POC_USERS_WITH_SMALL_REWARDS_POOL_SIZE
    * POC_USER_SMALL_REWARD_MAX_TOKEN_AMOUNT + POC_USER_EARLY_CLAIM_MAX_TOKEN_AMOUNT; // = 50_000 *
    // 10e2 + 500e2 = 500_000e2 + 500e2 = 500_500e2
  uint16 internal constant POC_BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1 = 500; // 5%
  uint16 internal constant POC_EARLY_VEST_RATIO_MIN_P1_S1 = 500; // 5%
  uint16 internal constant POC_EARLY_VEST_RATIO_MAX_P1_S1 = 9500; // 95%

  modifier poc__WhenTokensAreDepositedForTheProject() {
    _changePrank(PROJECT_ADMIN);
    uint256 totalTokenAmount = POC_TOKEN_AMOUNT_P1_S1;
    s_token.approve(address(s_claim), totalTokenAmount);
    s_claim.deposit(totalTokenAmount);
    _;
  }

  modifier poc__whenASeasonConfigIsSetForTheProject() {
    _changePrank(ADMIN);
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: POC_TOKEN_AMOUNT_P1_S1,
        baseTokenClaimBps: POC_BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: UNLOCK_DURATION_S1,
        merkleRoot: MERKLE_ROOT_P1_S1,
        earlyVestRatioMinBps: POC_EARLY_VEST_RATIO_MIN_P1_S1,
        earlyVestRatioMaxBps: POC_EARLY_VEST_RATIO_MAX_P1_S1,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);
    _;
  }

  function test_loyaltyBonusZero()
    public
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    poc__WhenTokensAreDepositedForTheProject
    poc__whenASeasonConfigIsSetForTheProject
  {
    uint256 timestampUnlockDelayHasEnded =
      block.timestamp + UNLOCK_START_TIME_S1 + UNLOCK_DELAY_P1_S1;
    vm.warp(timestampUnlockDelayHasEnded);

    // 1) User1 early claims immediately, giving away 90% of their tokens as loyalty bonus
    _changePrank(USER_1);
    IBUILDClaim.ClaimParams[] memory earlyClaimerParams = new IBUILDClaim.ClaimParams[](1);
    earlyClaimerParams[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: POC_USER_EARLY_CLAIM_MAX_TOKEN_AMOUNT,
      salt: SALT_U2,
      isEarlyClaim: true
    });
    s_claim.claim(USER_1, earlyClaimerParams);

    // 2) A large pool of users performs claim after unlock finishes (eligible for loyalty bonus)
    uint256 timestampUnlockPeriodHasEnded = block.timestamp + UNLOCK_DURATION_S1 + 1;
    vm.warp(timestampUnlockPeriodHasEnded);

    address[] memory userPool = new address[](POC_USERS_WITH_SMALL_REWARDS_POOL_SIZE);
    // //50k
    // users
    // with max token amount = 10USD
    IBUILDClaim.ClaimParams[] memory userWithSmallRewardParams = new IBUILDClaim.ClaimParams[](1);
    userWithSmallRewardParams[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: POC_USER_SMALL_REWARD_MAX_TOKEN_AMOUNT, //10e2
      salt: SALT_U2,
      isEarlyClaim: false
    });
    for (uint256 i = 0; i < userPool.length; i++) {
      address user = address(uint160(uint256(keccak256(abi.encodePacked("user", i)))));
      userPool[i] = user;
      _changePrank(user);
      s_claim.claim(user, userWithSmallRewardParams);
    }

    _changePrank(ADMIN);
    s_factory.startRefund(address(s_token), SEASON_ID_S1);

    // 6) show that none of the 50k users has claimed any loyalty bonus
    IBUILDClaim.GlobalState memory globalState = s_claim.getGlobalState(SEASON_ID_S1);
    uint256 maxWithdrawable = s_factory.calcMaxAvailableAmount(address(s_token));

    console.log("Loyalty pool: %s", globalState.totalLoyalty);
    console.log("Total claimed amount: %s", globalState.totalClaimed);
    console.log("Total project token amount: %s", POC_TOKEN_AMOUNT_P1_S1);
    console.log("===================================================\n");
    console.log("Max withdrawable amount by the project: %s", maxWithdrawable);
    console.log("Unclaimed loyalty tokens: %s", POC_TOKEN_AMOUNT_P1_S1 - globalState.totalClaimed);
  }
}
