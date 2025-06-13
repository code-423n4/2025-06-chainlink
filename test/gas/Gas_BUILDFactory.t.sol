// SPDX-License-Identifier: MIT
/* solhint-disable one-contract-per-file */
pragma solidity 0.8.26;

import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

contract Gas_BUILDFactory_DeployClaim is BaseTest {
  function setUp() public {
    _changePrank(ADMIN);
    IBUILDFactory.AddProjectParams[] memory input = new IBUILDFactory.AddProjectParams[](1);
    input[0] = IBUILDFactory.AddProjectParams({token: address(s_token), admin: PROJECT_ADMIN});
    s_factory.addProjects(input);

    _changePrank(PROJECT_ADMIN);
  }

  function test_Gas_DeployClaim() external {
    s_claim = s_factory.deployClaim(address(s_token));
  }
}

contract Gas_BUILDFactory_AddProjects is BaseTest {
  function setUp() public {
    _changePrank(ADMIN);
  }

  function test_Gas_AddProjects() external {
    IBUILDFactory.AddProjectParams[] memory input = new IBUILDFactory.AddProjectParams[](1);
    input[0] = IBUILDFactory.AddProjectParams({token: address(s_token), admin: PROJECT_ADMIN});
    s_factory.addProjects(input);
  }
}

contract Gas_BUILDFactory_RemoveProjects is BaseTest {
  function setUp() public whenProjectAdded {
    _changePrank(ADMIN);
  }

  function test_Gas_RemoveProjects() external {
    address[] memory removals = new address[](1);
    removals[0] = address(s_token);
    s_factory.removeProjects(removals);
  }
}

contract Gas_BUILDFactory_SetSeasonUnlockStartTime is BaseTest {
  function setUp() public {
    _changePrank(ADMIN);
  }

  function test_Gas_setSeasonUnlockStartTime() external {
    uint40 unlockStartsAt = uint40(block.timestamp) + UNLOCK_START_TIME_S1;
    s_factory.setSeasonUnlockStartTime(SEASON_ID_S1, unlockStartsAt);
  }
}

contract Gas_BUILDFactory_SetProjectSeasonConfig is BaseTest {
  function setUp()
    public
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
  {
    _changePrank(ADMIN);
  }

  function test_Gas_SetProjectSeasonConfig() external {
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: TOKEN_AMOUNT_P1_S1,
        baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: UNLOCK_DURATION_S1,
        merkleRoot: MERKLE_ROOT_P1_S1,
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S1,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S1,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);
  }
}

contract Gas_BUILDFactory_StartRefund is BaseTest {
  function setUp()
    public
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
  {
    _changePrank(ADMIN);
  }

  function test_Gas_StartRefund() external {
    s_factory.startRefund(address(s_token), SEASON_ID_S1);
  }
}
