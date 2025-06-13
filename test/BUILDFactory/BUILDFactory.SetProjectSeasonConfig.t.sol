// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";
import {Closable} from "./../../src/Closable.sol";

/// @notice Requirements
/// [BUS1.3.1](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=c7f247ac-4645-419d-b807-132179cc0863&fieldId=28d1c574-a71d-5e3e-babb-d23bb4454358)
/// [BUS1.3.2](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=6240aa59-64d1-4ef7-b777-a1b4bb34d20a&fieldId=28d1c574-a71d-5e3e-babb-d23bb4454358)
/// [BUS1.3.4](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=fcd832b6-926b-4c64-a91a-717f5e53acd1&fieldId=28d1c574-a71d-5e3e-babb-d23bb4454358)
/// [BUS1.6](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=1653eb50-6aaf-4a8c-904d-e7e3a46f4016)
/// [BUS2.6.2](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=577087a2-3ee0-4205-ac69-966bc2097eaa&fieldId=28d1c574-a71d-5e3e-babb-d23bb4454358)
/// [BUS2.6.1.1](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=2fbcf65c-becd-4f69-bf97-8495d94e52af&fieldId=28d1c574-a71d-5e3e-babb-d23bb4454358)
/// [BUS2.8](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=7ed9c509-42c8-4f1a-b027-4bb40ae7fd4a&fieldId=28d1c574-a71d-5e3e-babb-d23bb4454358)
/// [LEG4.1.2](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=95af5359-0724-4f9e-8d31-8331783339d1&fieldId=28d1c574-a71d-5e3e-babb-d23bb4454358)
/// [LEG4.1.1](https://smartcontract-it.atlassian.net/wiki/spaces/ECON/database/657686775?contentId=657686775&entryId=02ddb28f-3d31-4411-a3f5-e2da5c1e1500&fieldId=28d1c574-a71d-5e3e-babb-d23bb4454358)
contract BUILDFactorySetProjectSeasonConfigTest is BaseTest {
  function test_RevertWhen_TheCallerIsNotFactoryAdmin() external whenProjectAddedAndClaimDeployed {
    _changePrank(NOBODY);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector,
        NOBODY,
        s_factory.DEFAULT_ADMIN_ROLE()
      )
    );
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: 100,
        baseTokenClaimBps: 0,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 1,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);
  }

  modifier whenTheCallerIsFactoryAdmin() {
    assertEq(s_factory.hasRole(s_factory.DEFAULT_ADMIN_ROLE(), ADMIN), true);
    _changePrank(ADMIN);
    _;
  }

  function test_RevertWhen_TheFactoryIsClosed()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenFactoryClosed
    whenTheCallerIsFactoryAdmin
  {
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(Closable.AlreadyClosed.selector));
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: 100,
        baseTokenClaimBps: 0,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 1,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);
  }

  function test_RevertWhen_ASeasonConfigIsNotSetForTheSeason()
    external
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsFactoryAdmin
  {
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.SeasonDoesNotExist.selector, SEASON_ID_S1));
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: 100,
        baseTokenClaimBps: 0,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 1,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);
  }

  function test_RevertWhen_TheProjectIsNotAdded()
    external
    whenASeasonConfigIsSetForTheSeason
    whenTheCallerIsFactoryAdmin
  {
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(IBUILDFactory.ProjectDoesNotExist.selector, address(s_token))
    );
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: 100,
        baseTokenClaimBps: 0,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 1,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);
  }

  function test_RevertWhen_ASeasonAlreadyStartedUnlocking()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsFactoryAdmin
  {
    skip(UNLOCK_START_TIME_S1 + 1);
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(IBUILDFactory.SeasonAlreadyStarted.selector, SEASON_ID_S1)
    );
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: 100,
        baseTokenClaimBps: 0,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 1,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);
  }

  function test_RevertWhen_TheProjectStartedRefundingForTheSeason()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheCallerIsFactoryAdmin
  {
    s_factory.startRefund(address(s_token), SEASON_ID_S1);

    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.ProjectSeasonIsRefunding.selector, address(s_token), SEASON_ID_S1
      )
    );
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: 100,
        baseTokenClaimBps: 0,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 1,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);
  }

  function test_RevertWhen_TheUnlockDurationIsZero()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsFactoryAdmin
  {
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: 100,
        baseTokenClaimBps: 0,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 0,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(IBUILDFactory.InvalidUnlockDuration.selector, SEASON_ID_S1, 0)
    );
    s_factory.setProjectSeasonConfig(params);
  }

  function test_RevertWhen_TheUnlockDurationExceedsTheMaxUnlockDuration()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsFactoryAdmin
  {
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: 100,
        baseTokenClaimBps: 0,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: MAX_UNLOCK_DURATION + 1,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.InvalidUnlockDuration.selector, SEASON_ID_S1, MAX_UNLOCK_DURATION + 1
      )
    );
    s_factory.setProjectSeasonConfig(params);
  }

  function test_RevertWhen_TheUnlockDelayExceedsTheMaxUnlockDelay()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsFactoryAdmin
  {
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: 100,
        baseTokenClaimBps: 0,
        unlockDelay: MAX_UNLOCK_DELAY + 1,
        unlockDuration: 1,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.InvalidUnlockDelay.selector, SEASON_ID_S1, MAX_UNLOCK_DELAY + 1
      )
    );
    s_factory.setProjectSeasonConfig(params);
  }

  function test_RevertWhen_TheTokenAmountIsZero()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsFactoryAdmin
  {
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: 0,
        baseTokenClaimBps: 0,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 1,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.InvalidTokenAmount.selector, SEASON_ID_S1));
    s_factory.setProjectSeasonConfig(params);
  }

  function test_RevertWhen_TheTokenAmountIsGreaterThanMaxUint248()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsFactoryAdmin
  {
    // it should revert
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: uint256(type(uint248).max) + 1,
        baseTokenClaimBps: 0,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 1,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.InvalidTokenAmount.selector, SEASON_ID_S1));
    s_factory.setProjectSeasonConfig(params);
  }

  function test_RevertWhen_TheTokenAmountExceedsTheMaxAvailableAmount()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenTheCallerIsFactoryAdmin
  {
    uint256 maxAvailable = s_factory.calcMaxAvailableAmount(address(s_token));
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: maxAvailable + 1,
        baseTokenClaimBps: 0,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 1,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.InsufficientFunds.selector,
        address(s_token),
        SEASON_ID_S1,
        maxAvailable + 1,
        maxAvailable
      )
    );
    s_factory.setProjectSeasonConfig(params);
  }

  function test_RevertWhen_ThebaseTokenClaimBpsIsGreaterThan10000()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsFactoryAdmin
  {
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: 100,
        baseTokenClaimBps: 10001,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 1,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.InvalidBaseTokenClaimBps.selector, SEASON_ID_S1, 10001, 1
      )
    );
    s_factory.setProjectSeasonConfig(params);
  }

  function test_RevertWhen_ThebaseTokenClaimBpsIs10000AndUnlockDurationIsGreaterThan1()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsFactoryAdmin
  {
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: 100,
        baseTokenClaimBps: MAX_BASE_TOKEN_CLAIM_PERCENTAGE,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 2,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
        isRefunding: false
      })
    });
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.InvalidBaseTokenClaimBps.selector,
        SEASON_ID_S1,
        MAX_BASE_TOKEN_CLAIM_PERCENTAGE,
        2
      )
    );
    s_factory.setProjectSeasonConfig(params);
  }

  function test_RevertWhen_TheEarlyClaimMinRatioIsLargerThanTheMaxRatio()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsFactoryAdmin
  {
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: 100,
        baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 1,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2 + 1,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MIN_P1_S2,
        isRefunding: false
      })
    });
    // it should revert
    vm.expectRevert(
      abi.encodeWithSelector(
        IBUILDFactory.InvalidEarlyVestRatios.selector,
        EARLY_VEST_RATIO_MIN_P1_S2 + 1,
        EARLY_VEST_RATIO_MIN_P1_S2
      )
    );
    s_factory.setProjectSeasonConfig(params);
  }

  function test_RevertWhen_TheEarlyClaimMaxRatioIsGreaterThan10000()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTheCallerIsFactoryAdmin
  {
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: 100,
        baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 1,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: 0,
        earlyVestRatioMaxBps: 10001,
        isRefunding: false
      })
    });
    // it should revert
    vm.expectRevert(abi.encodeWithSelector(IBUILDFactory.InvalidEarlyVestRatios.selector, 0, 10001));
    s_factory.setProjectSeasonConfig(params);
  }

  modifier whenTheSeasonConfigIsSetAndParamsAreValid() {
    _;
  }

  function test_TheEarlyClaimMinRatioIsEqualToTheMaxRatio()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenTheCallerIsFactoryAdmin
  {
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: 1,
        baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 1,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MAX_P1_S1,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S1,
        isRefunding: false
      })
    });
    // it should not revert
    s_factory.setProjectSeasonConfig(params);
  }

  function test_TheIsRefundingFlagIsTurnedOn()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenTheCallerIsFactoryAdmin
  {
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: 100,
        baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 1,
        merkleRoot: bytes32(0),
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S1,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S1,
        isRefunding: true
      })
    });
    // it should not revert
    s_factory.setProjectSeasonConfig(params);
    // it should have overridden the isRefunding flag
    (IBUILDFactory.ProjectSeasonConfig memory latestConfig,) =
      s_factory.getProjectSeasonConfig(address(s_token), SEASON_ID_S1);
    assertEq(latestConfig.isRefunding, false);
  }

  function test_WhenTheSeasonConfigIsSetAndParamsAreValid()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenTheCallerIsFactoryAdmin
  {
    IBUILDFactory.ProjectSeasonConfig memory newConfig = IBUILDFactory.ProjectSeasonConfig({
      tokenAmount: 100,
      baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1,
      unlockDelay: UNLOCK_DELAY_P1_S1,
      unlockDuration: 1,
      merkleRoot: bytes32(0),
      earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
      earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
      isRefunding: false
    });
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: newConfig
    });
    // it should emit events: ProjectTotalAllocatedUpdated, ProjectSeasonConfigUpdated
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.ProjectTotalAllocatedUpdated(
      address(s_token), 0, params[0].config.tokenAmount
    );
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.ProjectSeasonConfigUpdated(address(s_token), SEASON_ID_S1, newConfig);
    s_factory.setProjectSeasonConfig(params);

    // it should set the project season config
    (IBUILDFactory.ProjectSeasonConfig memory latestConfig,) =
      s_factory.getProjectSeasonConfig(address(s_token), SEASON_ID_S1);
    assertEq(latestConfig.tokenAmount, params[0].config.tokenAmount);
    assertEq(latestConfig.baseTokenClaimBps, params[0].config.baseTokenClaimBps);
    assertEq(latestConfig.unlockDelay, params[0].config.unlockDelay);
    assertEq(latestConfig.unlockDuration, params[0].config.unlockDuration);
    assertEq(latestConfig.merkleRoot, params[0].config.merkleRoot);
    assertEq(latestConfig.isRefunding, false);
  }

  function test_WhenTheSeasonConfigIsUpdated()
    external
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
    whenTheCallerIsFactoryAdmin
  {
    (IBUILDFactory.ProjectSeasonConfig memory configBefore,) =
      s_factory.getProjectSeasonConfig(address(s_token), SEASON_ID_S1);
    IBUILDFactory.TokenAmounts memory amountsBefore = s_factory.getTokenAmounts(address(s_token));

    IBUILDFactory.ProjectSeasonConfig memory newConfig = IBUILDFactory.ProjectSeasonConfig({
      tokenAmount: configBefore.tokenAmount + 1,
      baseTokenClaimBps: configBefore.baseTokenClaimBps + 1,
      unlockDelay: configBefore.unlockDelay + 1,
      unlockDuration: configBefore.unlockDuration + 1,
      merkleRoot: bytes32(0),
      earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
      earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
      isRefunding: false
    });
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: newConfig
    });
    // it should emit events: ProjectTotalAllocatedUpdated, ProjectSeasonConfigUpdated
    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.ProjectTotalAllocatedUpdated(
      address(s_token),
      amountsBefore.totalAllocatedToAllSeasons,
      amountsBefore.totalAllocatedToAllSeasons - configBefore.tokenAmount
        + params[0].config.tokenAmount
    );

    vm.expectEmit(address(s_factory));
    emit IBUILDFactory.ProjectSeasonConfigUpdated(address(s_token), SEASON_ID_S1, newConfig);
    s_factory.setProjectSeasonConfig(params);

    // it should update the project season config
    (IBUILDFactory.ProjectSeasonConfig memory latestConfig,) =
      s_factory.getProjectSeasonConfig(address(s_token), SEASON_ID_S1);
    assertEq(latestConfig.tokenAmount, params[0].config.tokenAmount);
    assertEq(latestConfig.baseTokenClaimBps, params[0].config.baseTokenClaimBps);
    assertEq(latestConfig.unlockDelay, params[0].config.unlockDelay);
    assertEq(latestConfig.unlockDuration, params[0].config.unlockDuration);
    assertEq(latestConfig.merkleRoot, params[0].config.merkleRoot);
    assertEq(latestConfig.earlyVestRatioMinBps, params[0].config.earlyVestRatioMinBps);
    assertEq(latestConfig.earlyVestRatioMaxBps, params[0].config.earlyVestRatioMaxBps);

    // it should not change the isRefunding status
    assertEq(latestConfig.isRefunding, configBefore.isRefunding);
    // it should correctly update the allocated token amount
    IBUILDFactory.TokenAmounts memory amountsAfter = s_factory.getTokenAmounts(address(s_token));
    assertEq(
      amountsAfter.totalAllocatedToAllSeasons,
      amountsBefore.totalAllocatedToAllSeasons - configBefore.tokenAmount
        + params[0].config.tokenAmount
    );
  }
}
