// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {Handler} from "./handlers/Handler.t.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";
import {BUILDFactory} from "./../../src/BUILDFactory.sol";

/// @title This contract sets up the invariant tests by deploying the target and handler contracts
/// and registering the target selectors.
/// @dev The tests are done with 2 projects (BUILDClaim contracts), each with an ID of 1 and 2.
contract BaseInvariant is StdInvariant, BaseTest {
  Handler internal s_handler;

  function setUp() public virtual {
    // Add project 1 and 2
    _addProjects();

    // Deploy the BUILDClaim contracts for the projects
    _deployClaims();

    // Deposit 1 season worth of tokens into the BUILDClaim contracts
    _depositTokens();

    // Set the season configuration for 1 season for each project
    _setSeasonUnlockStartTime();

    // Set user delegation for multicall
    _setupDelegation();

    s_handler =
      new Handler(s_factory, s_claim, s_claim_2, s_multicall, s_multisigWallet, s_multiSendCallOnly);
    targetContract(address(s_handler));
    bytes4[] memory targetHandlerSelectors = new bytes4[](5);
    targetHandlerSelectors[0] = Handler.addSeason.selector;
    targetHandlerSelectors[1] = Handler.deposit.selector;
    targetHandlerSelectors[2] = Handler.withdraw.selector;
    targetHandlerSelectors[3] = Handler.startRefund.selector;
    targetHandlerSelectors[4] = Handler.claim.selector;
    targetSelector(FuzzSelector({addr: address(s_handler), selectors: targetHandlerSelectors}));

    excludeContract(address(s_factory));
    excludeContract(address(s_token));
    excludeContract(address(s_token_2));
    excludeContract(address(s_claim));
    excludeContract(address(s_claim_2));
    excludeContract(address(s_multicall));
    excludeContract(address(s_multiSendCallOnly));
    excludeContract(address(s_multisigWallet));
  }

  function _addProjects() private {
    _changePrank(ADMIN);
    BUILDFactory.AddProjectParams[] memory input = new BUILDFactory.AddProjectParams[](2);
    input[0] = IBUILDFactory.AddProjectParams({token: address(s_token), admin: PROJECT_ADMIN});
    input[1] = IBUILDFactory.AddProjectParams({token: address(s_token_2), admin: PROJECT_ADMIN});
    s_factory.addProjects(input);
  }

  function _deployClaims() private {
    _changePrank(PROJECT_ADMIN);
    s_claim = s_factory.deployClaim(address(s_token));
    s_claim_2 = s_factory.deployClaim(address(s_token_2));
  }

  function _depositTokens() private {
    _changePrank(PROJECT_ADMIN);
    s_token.approve(address(s_claim), TOKEN_AMOUNT_P1_S1);
    s_claim.deposit(TOKEN_AMOUNT_P1_S1);
    s_token_2.approve(address(s_claim_2), TOKEN_AMOUNT_P2_S1);
    s_claim_2.deposit(TOKEN_AMOUNT_P2_S1);
  }

  /// @dev We set a season for each project so that there are some tokens to claim from the start.
  /// @dev We configure the seasons so that there are some overlapping periods.
  function _setSeasonUnlockStartTime() private {
    _changePrank(ADMIN);
    uint256 unlockStartsAt = block.timestamp + 1 days;
    s_factory.setSeasonUnlockStartTime(SEASON_ID_S1, unlockStartsAt);

    IBUILDFactory.SetProjectSeasonParams[] memory configP1S1 =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    configP1S1[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: TOKEN_AMOUNT_P1_S1,
        baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1,
        unlockDelay: UNLOCK_DELAY_P1_S1,
        unlockDuration: 100 days,
        merkleRoot: MERKLE_ROOT_P1_S1,
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S1,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S1,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(configP1S1);
    IBUILDFactory.SetProjectSeasonParams[] memory configP2S1 =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    configP2S1[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token_2),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: TOKEN_AMOUNT_P2_S1,
        baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P2_S1,
        unlockDelay: UNLOCK_DELAY_P2_S1,
        unlockDuration: 100 days,
        merkleRoot: MERKLE_ROOT_P2_S1,
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S1,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S1,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(configP2S1);
  }

  /// @dev We set up delegation to the multicall contract so the multicall contract is able to
  /// regular and early claim for users
  function _setupDelegation() private {
    address[] memory users = _getUsers();
    for (uint256 i = 0; i < users.length; i++) {
      _delegateUser(users[i], address(s_multicall), address(s_factory));
    }
  }

  // added to be excluded from coverage report
  function test() public virtual override {}
}
