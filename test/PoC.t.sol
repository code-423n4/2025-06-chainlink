pragma solidity 0.8.26;

import {BaseTest} from "./BaseTest.t.sol";
import {Constants} from "./Constants.t.sol";
import "src/BUILDClaim.sol";
import "src/BUILDFactory.sol";
import {console} from "forge-std/Script.sol";

contract PoC is BaseTest {
  function test_loyaltyBonusZero() public pocSetupSeason1 {
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
    s_claim_poc.claim(USER_1, earlyClaimerParams);

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
      s_claim_poc.claim(user, userWithSmallRewardParams);
    }

    _changePrank(ADMIN);
    s_factory.startRefund(address(s_token_poc), SEASON_ID_S1);

    // 6) show that none of the 50k users has claimed any loyalty bonus
    IBUILDClaim.GlobalState memory globalState = s_claim_poc.getGlobalState(SEASON_ID_S1);
    uint256 maxWithdrawable = s_factory.calcMaxAvailableAmount(address(s_token_poc));

    console.log("Loyalty pool: %s", globalState.totalLoyalty);
    console.log("Total claimed amount: %s", globalState.totalClaimed);
    console.log("Total project token amount: %s", POC_TOKEN_AMOUNT_P1_S1);
    console.log("===================================================\n");
    console.log("Max withdrawable amount by the project: %s", maxWithdrawable);
    console.log("Unclaimed loyalty tokens: %s", POC_TOKEN_AMOUNT_P1_S1 - globalState.totalClaimed);
  }
}
