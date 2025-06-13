// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Constants} from "../../Constants.t.sol";
import {Utils} from "../../Utils.t.sol";
import {IBUILDClaim} from "../../../src/interfaces/IBUILDClaim.sol";
import {IBUILDFactory} from "../../../src/interfaces/IBUILDFactory.sol";
import {BUILDFactory} from "../../../src/BUILDFactory.sol";
import {BUILDClaim} from "../../../src/BUILDClaim.sol";
import {MultiSendCallOnly} from "../../../src/mocks/MultiSendCallOnly.sol";
import {MultisigWallet} from "../../../src/mocks/MultisigWallet.sol";
import {Multicall3} from "../../../src/mocks/Multicall3.sol";

/// @title This contract is used to test the invariants of the BUILDFactory and BUILDClaim
/// contracts.
/// Functions exposed to the fuzzer:
/// - setSeasonUnlockStartTime
/// - setProjectSeasonConfig
/// - deposit
/// - withdraw
/// - startRefund
/// - claim
contract Handler is Test, Constants, Utils {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @notice The struct used to store the user's max token amounts and merkle proofs
  struct UserInfo {
    /// @notice The user's address
    address user;
    /// @notice The user's max token amount for the particular project's season
    uint256 maxTokenAmount;
    /// @notice The user's salt used to generate the merkle proof
    uint256 salt;
    /// @notice The user's merkle proof
    bytes32[] proof;
    /// @notice The user's early claim merkle proof
    bytes32[] proofEarly;
  }

  /// @notice The struct used to get the seeds for the projects and seasons as the input to the
  /// fuzzed claim function
  struct ProjectSeasonSeeds {
    /// @notice The seed to determine the project (false = project 1, true = project 2)
    bool project;
    /// @notice The seed to determine the season
    uint32 season;
  }

  /// @notice The struct used to get the seeds for the new project seasons as the input to the
  /// fuzzed addSeason function
  struct NewProjectSeasonSeeds {
    /// @notice The seed to determine the project (false = project 1, true = project 2)
    bool project;
    /// @notice The seed to determine the unlock duration
    uint24 unlockDuration;
    /// @notice The seed to determine the unlock delay
    uint24 unlockDelay;
    /// @notice The seed to determine the base token claim percentage
    uint16 baseTokenClaimBps;
    /// @notice The seed to determine the token amount
    uint256 tokenAmount;
  }

  /// @notice The BUILDFactory contract
  BUILDFactory private s_factory;
  /// @notice The BUILDClaim contract for project 1
  IBUILDClaim private s_claim_1;
  /// @notice The BUILDClaim contract for project 2
  IBUILDClaim private s_claim_2;
  /// @notice The Multicall3 contract
  Multicall3 private s_multicall;
  /// @notice The MultisigWallet contract
  MultisigWallet private s_multisigWallet;
  /// @notice The MultiSendCallOnly contract used for batched transactions in the multisig wallet
  MultiSendCallOnly private s_multiSendCallOnly;

  /// @notice The mapping of projects to user's max token amounts and merkle proofs
  UserInfo[3][2] internal s_userInfo;

  /// @notice The claim params for each BUILDClaim contract within the current claim fuzz call.
  /// These get reset after each claim fuzzing call.
  mapping(IBUILDClaim => IBUILDClaim.ClaimParams[]) internal s_claimParams;

  /// @notice The set of BUILDClaim contracts to claim from within the current claim fuzz call.
  /// These get reset after each claim fuzzing call.
  EnumerableSet.AddressSet internal s_projectsSet;

  /// @notice The season ID to be used for the next season
  uint32 internal s_nextSeasonId;

  /// @notice The last season ID created for each project
  uint32[3] internal s_projectMaxSeasonId;

  constructor(
    BUILDFactory buildFactory,
    IBUILDClaim buildClaim1,
    IBUILDClaim buildClaim2,
    Multicall3 multicall,
    MultisigWallet multisigWallet,
    MultiSendCallOnly multiSendCallOnly
  ) {
    s_factory = buildFactory;
    s_claim_1 = buildClaim1;
    s_claim_2 = buildClaim2;
    s_multicall = multicall;
    s_multisigWallet = multisigWallet;
    s_multiSendCallOnly = multiSendCallOnly;
    // Starts with project 1 and 2 both having 1 season
    s_nextSeasonId = 2;
    s_projectMaxSeasonId[1] = 1;
    s_projectMaxSeasonId[2] = 1;

    _addUsers();
  }

  /// @notice Fuzzes BUILDFactory.setSeasonUnlockStartTime and BUILDFactory.setProjectSeasonConfig
  /// @param unlockStartsAtSeed The seed to determine the time that the season unlock starts at
  /// @param newProjectSeasonSeeds The seeds to determine the new project seasons
  function addSeason(
    uint24 unlockStartsAtSeed,
    NewProjectSeasonSeeds[2] memory newProjectSeasonSeeds
  ) public {
    _changePrank(ADMIN);
    s_factory.setSeasonUnlockStartTime(
      s_nextSeasonId, block.timestamp + bound(unlockStartsAtSeed, 1, 1 days)
    );

    for (uint256 i; i < newProjectSeasonSeeds.length; ++i) {
      NewProjectSeasonSeeds memory newProjectSeasonSeed = newProjectSeasonSeeds[i];
      (uint256 projectId, IBUILDClaim targetClaim, IERC20 token) =
        _seedToProject(newProjectSeasonSeed.project);
      // skip if the project season is already configured
      if (s_projectMaxSeasonId[projectId] == s_nextSeasonId) {
        continue;
      }
      uint256 balance = token.balanceOf(PROJECT_ADMIN);
      uint256 minTokenAmount = _getMinTokenAmount(projectId);
      if (balance < minTokenAmount) {
        continue;
      }
      uint16 baseTokenClaimBps =
        uint16(bound(newProjectSeasonSeed.baseTokenClaimBps, 0, MAX_BASE_TOKEN_CLAIM_PERCENTAGE));
      uint40 unlockDuration = baseTokenClaimBps == MAX_BASE_TOKEN_CLAIM_PERCENTAGE
        ? 1
        : uint40(bound(newProjectSeasonSeed.unlockDuration, 1, 365 days));
      IBUILDFactory.SetProjectSeasonParams[] memory params =
        new IBUILDFactory.SetProjectSeasonParams[](1);
      params[0] = IBUILDFactory.SetProjectSeasonParams({
        token: address(token),
        seasonId: s_nextSeasonId,
        config: IBUILDFactory.ProjectSeasonConfig({
          tokenAmount: bound(newProjectSeasonSeed.tokenAmount, minTokenAmount, balance),
          unlockDuration: unlockDuration,
          unlockDelay: newProjectSeasonSeed.unlockDelay,
          baseTokenClaimBps: baseTokenClaimBps,
          merkleRoot: _projectIdToMerkleRoot(projectId),
          earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S2,
          earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S2,
          isRefunding: false
        })
      });

      _changePrank(PROJECT_ADMIN);
      token.approve(address(targetClaim), params[0].config.tokenAmount);
      targetClaim.deposit(params[0].config.tokenAmount);

      _changePrank(ADMIN);
      s_factory.setProjectSeasonConfig(params);

      s_projectMaxSeasonId[projectId] = s_nextSeasonId;
    }

    s_nextSeasonId++;
  }

  /// @notice Fuzzes BUILDClaim.deposit
  /// @param projectSeed The seed to determine the project
  /// @param amount The seed to determine the deposit amount
  function deposit(bool projectSeed, uint256 amount) public {
    (, IBUILDClaim targetClaim, IERC20 token) = _seedToProject(projectSeed);
    uint256 balance = token.balanceOf(PROJECT_ADMIN);
    amount = bound(amount, 0, balance);
    if (amount == 0) return;

    _changePrank(PROJECT_ADMIN);
    token.approve(address(targetClaim), amount);
    targetClaim.deposit(amount);
  }

  /// @notice Fuzzes BUILDClaim.withdraw
  /// @param projectSeed The seed to determine the project
  /// @param amount The seed to determine the withdraw amount
  function withdraw(bool projectSeed, uint256 amount) public {
    (, IBUILDClaim targetClaim, IERC20 token) = _seedToProject(projectSeed);
    uint256 maxWithdrawable = s_factory.calcMaxAvailableAmount(address(token));
    amount = bound(amount, 0, maxWithdrawable);
    if (amount == 0) {
      return;
    }

    _changePrank(ADMIN);
    s_factory.scheduleWithdraw(address(token), PROJECT_ADMIN, amount);
    uint256 contractBalanceBefore = token.balanceOf(address(targetClaim));
    uint256 projectAdminBalanceBefore = token.balanceOf(address(PROJECT_ADMIN));

    _changePrank(PROJECT_ADMIN);
    targetClaim.withdraw();

    assertEq(token.balanceOf(address(targetClaim)), contractBalanceBefore - amount);
    assertEq(token.balanceOf(address(PROJECT_ADMIN)), projectAdminBalanceBefore + amount);
    assertEq(s_factory.calcMaxAvailableAmount(address(token)), maxWithdrawable - amount);
  }

  /// @notice Fuzzes BUILDFactory.startRefund
  /// @param projectSeed The seed to determine the project
  /// @param seasonSeed The seed to determine the season
  function startRefund(bool projectSeed, uint32 seasonSeed) public {
    (uint256 projectId,, IERC20 token) = _seedToProject(projectSeed);
    uint32 seasonId = _seedToSeason(projectId, seasonSeed);
    // season for the project is not configured
    (IBUILDFactory.ProjectSeasonConfig memory config,) =
      s_factory.getProjectSeasonConfig(address(token), seasonId);
    if (config.tokenAmount == 0) {
      return;
    }
    if (s_factory.isRefunding(address(token), seasonId)) {
      return;
    }

    _changePrank(ADMIN);
    s_factory.startRefund(address(token), seasonId);
  }

  /// @notice Fuzzes BUILDClaim.claim
  /// @param projectSeasonSeeds The seeds to determine the projects and seasons
  /// @param numProjectSeasonsSeed The number of project seasons to claim from
  /// @param userSeed The seed to determine the user
  /// @param timeSeed The seed to determine how much time to skip
  /// @param isEarlyClaimSeed The seed to determine if claim for season is early claim
  function claim(
    ProjectSeasonSeeds[100] memory projectSeasonSeeds,
    uint8 numProjectSeasonsSeed,
    uint8 userSeed,
    uint256 timeSeed,
    bool[100] memory isEarlyClaimSeed
  ) public {
    (uint256 userId, address user, bool isMsig) = _seedToUser(userSeed);
    uint256 numProjectSeasons = bound(uint256(numProjectSeasonsSeed), 1, projectSeasonSeeds.length);
    uint256[] memory claimedAndClaimableBefore = new uint256[](numProjectSeasons);
    uint256 latestUnlockStartTime;

    // track previous earlyClaims per season in same transaction
    // deduplicate earlyClaims (1 indexed)
    bool[][3] memory hasNewEarlyClaim;
    hasNewEarlyClaim[1] = new bool[](s_projectMaxSeasonId[1] + 1);
    hasNewEarlyClaim[2] = new bool[](s_projectMaxSeasonId[2] + 1);

    // collect all the projects and seasons to claim from and the claim params
    for (uint256 i; i < numProjectSeasons; ++i) {
      ProjectSeasonSeeds memory projectSeason = projectSeasonSeeds[i];
      (uint256 projectId, IBUILDClaim targetClaim, IERC20 token) =
        _seedToProject(projectSeason.project);
      uint32 seasonId = _seedToSeason(projectId, projectSeason.season);
      projectSeason.season = seasonId;
      UserInfo memory userInfo = _getUserInfo(projectId, userId);
      bool isEarlyClaim = isEarlyClaimSeed[i];

      // skip if the project season is refunding and the user has not claimed any tokens
      IBUILDClaim.UserState memory userState =
        targetClaim.getUserState(_singleUserState(userInfo.user, seasonId))[0];
      if (s_factory.isRefunding(address(token), seasonId) && userState.claimed == 0) {
        continue;
      }
      // skip if the project season is not configured
      (IBUILDFactory.ProjectSeasonConfig memory config, uint256 unlockStartsAt) =
        s_factory.getProjectSeasonConfig(address(token), seasonId);
      if (config.tokenAmount == 0) {
        continue;
      }

      s_projectsSet.add(address(targetClaim));
      if (latestUnlockStartTime < unlockStartsAt + config.unlockDelay) {
        latestUnlockStartTime = unlockStartsAt + config.unlockDelay;
      }

      IBUILDClaim.ClaimParams memory claimParams = IBUILDClaim.ClaimParams({
        seasonId: seasonId,
        proof: isEarlyClaim ? userInfo.proofEarly : userInfo.proof,
        maxTokenAmount: userInfo.maxTokenAmount,
        salt: userInfo.salt,
        isEarlyClaim: isEarlyClaim
      });

      // skip claim if user has early claimed and season unlock is incomplete
      if (
        userState.hasEarlyClaimed && isEarlyClaim
          && block.timestamp < unlockStartsAt + config.unlockDelay + config.unlockDuration
      ) {
        // expect revert for attempted claim
        _changePrank(userInfo.user);
        vm.expectRevert(
          abi.encodeWithSelector(IBUILDClaim.InvalidEarlyClaim.selector, userInfo.user, seasonId)
        );
        IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
        params[0] = claimParams;
        targetClaim.claim(userInfo.user, params);
        continue;
      }

      // skip adding early claim if there is already an early claim (will cause revert)
      if (isEarlyClaim) {
        if (hasNewEarlyClaim[projectId][seasonId]) {
          continue;
        }
        hasNewEarlyClaim[projectId][seasonId] = true;
      }

      s_claimParams[targetClaim].push(claimParams);
    }

    // no project seasons to claim from due to refunding/not configured
    if (s_projectsSet.length() == 0) {
      return;
    }

    // skip time to the latest unlock start time
    _skipTime(timeSeed, latestUnlockStartTime);

    // collect the claimed and claimable amounts before claiming
    for (uint256 i; i < numProjectSeasons; ++i) {
      ProjectSeasonSeeds memory projectSeason = projectSeasonSeeds[i];
      (uint256 projectId, IBUILDClaim targetClaim,) = _seedToProject(projectSeason.project);
      uint32 seasonId = _seedToSeason(projectId, projectSeason.season);
      UserInfo memory userInfo = _getUserInfo(projectId, userId);

      IBUILDClaim.ClaimableState memory claimableState =
        targetClaim.getCurrentClaimValues(user, seasonId, userInfo.maxTokenAmount);
      claimedAndClaimableBefore[i] = claimableState.claimed + claimableState.claimable;

      // only add early vest bonus if:
      // there is an early claim
      if (hasNewEarlyClaim[projectId][seasonId]) {
        claimedAndClaimableBefore[i] += claimableState.earlyVestableBonus;
      }
    }

    // claim the tokens
    if (isMsig) {
      _changePrankTxOrigin(MSIG_DEPLOYER);
      if (s_projectsSet.length() == 1) {
        s_multisigWallet.execTransaction({
          to: s_projectsSet.at(0),
          data: abi.encodeWithSignature(
            "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])",
            user,
            s_claimParams[BUILDClaim(s_projectsSet.at(0))]
          ),
          useDelegateCall: false
        });
      } else {
        bytes memory multiSendData;
        for (uint256 i; i < s_projectsSet.length(); ++i) {
          bytes memory claimData = abi.encodeWithSignature(
            "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])",
            user,
            s_claimParams[BUILDClaim(s_projectsSet.at(i))]
          );
          multiSendData = bytes.concat(
            multiSendData,
            abi.encodePacked(
              uint8(0), // operation type (0 = call, 1 = delegatecall)
              s_projectsSet.at(i), // to
              uint256(0), // value
              uint256(claimData.length),
              claimData
            )
          );
        }
        s_multisigWallet.execTransaction({
          to: address(s_multiSendCallOnly),
          data: abi.encodeWithSignature("multiSend(bytes)", multiSendData),
          useDelegateCall: true
        });
      }
    } else {
      _changePrankTxOrigin(user);
      if (s_projectsSet.length() == 1) {
        BUILDClaim(s_projectsSet.at(0)).claim(user, s_claimParams[BUILDClaim(s_projectsSet.at(0))]);
      } else {
        Multicall3.Call3[] memory calls = new Multicall3.Call3[](s_projectsSet.length());
        for (uint256 i; i < s_projectsSet.length(); ++i) {
          calls[i] = Multicall3.Call3({
            target: s_projectsSet.at(i),
            allowFailure: true,
            callData: abi.encodeWithSignature(
              "claim(address,(uint32,bool,bytes32[],uint256,uint256)[])",
              user,
              s_claimParams[BUILDClaim(s_projectsSet.at(i))]
            )
          });
        }
        s_multicall.aggregate3(calls);
      }
    }

    // check the claimed and claimable amounts after claiming
    for (uint256 i; i < numProjectSeasons; ++i) {
      ProjectSeasonSeeds memory projectSeason = projectSeasonSeeds[i];
      (uint256 projectId, IBUILDClaim targetClaim,) = _seedToProject(projectSeason.project);
      uint32 seasonId = _seedToSeason(projectId, projectSeason.season);
      IBUILDClaim.UserState memory userState =
        targetClaim.getUserState(_singleUserState(user, seasonId))[0];
      assertEq(userState.claimed, claimedAndClaimableBefore[i]);
    }

    // clean up
    s_projectsSet.remove(address(s_claim_1));
    s_projectsSet.remove(address(s_claim_2));
    delete s_claimParams[s_claim_1];
    delete s_claimParams[s_claim_2];
  }

  /// @notice Returns the next season ID
  /// @return The next season ID
  function getNextSeasonId() external view returns (uint256) {
    return s_nextSeasonId;
  }

  /// @notice Util function for returning the user info for a particular project
  /// @param projectId The project id
  /// @param userId The user id
  /// @return The UserInfo struct for the user
  function _getUserInfo(uint256 projectId, uint256 userId) private view returns (UserInfo memory) {
    return s_userInfo[projectId - 1][userId];
  }

  /// @notice Adds users to be used in the tests
  /// @dev Only the users in the merkle trees can claim tokens, so we use those users for the
  /// invariant tests
  function _addUsers() private {
    // P1_S1_U1
    MERKLE_PROOF_P1_S1_U1 = new bytes32[](3);
    MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM = new bytes32[](3);
    MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM[0] =
      bytes32(0xb54e9297a0edd64b633e8d2f9e791117b171716b17b76278bf27589b7d7f9d66);
    MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM[1] =
      bytes32(0x520af8b06618203803e4e2800ca1af382b6f828aaf5128945cc7b4aec9efe379);
    MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM[2] =
      bytes32(0x6aa495d32d929f7b132783c2fb783ea998ab2d91d5a05a177f107f6b5b23d279);
    MERKLE_PROOF_P1_S1_U1[0] =
      bytes32(0x5283525448fadcf456a2b2efcc9a08f35a66447ae8f1336d45ad8b8464a7ba2d);
    MERKLE_PROOF_P1_S1_U1[1] =
      bytes32(0x2f103524c001053f53e4c4c58cfddc1fefc8f52e956781265be2aa2da4a5f524);
    MERKLE_PROOF_P1_S1_U1[2] =
      bytes32(0x6aa495d32d929f7b132783c2fb783ea998ab2d91d5a05a177f107f6b5b23d279);

    // P1_S1_U2
    MERKLE_PROOF_P1_S1_U2 = new bytes32[](3);
    MERKLE_PROOF_P1_S1_U2_EARLY_CLAIM = new bytes32[](3);
    MERKLE_PROOF_P1_S1_U2_EARLY_CLAIM[0] =
      bytes32(0x7edba859aaa0c715642724efdd6048ede272b2b8bea7c804970ca1af6945b966);
    MERKLE_PROOF_P1_S1_U2_EARLY_CLAIM[1] =
      bytes32(0x520af8b06618203803e4e2800ca1af382b6f828aaf5128945cc7b4aec9efe379);
    MERKLE_PROOF_P1_S1_U2_EARLY_CLAIM[2] =
      bytes32(0x6aa495d32d929f7b132783c2fb783ea998ab2d91d5a05a177f107f6b5b23d279);
    MERKLE_PROOF_P1_S1_U2[0] =
      bytes32(0x757035d44d585171d3bbb94a4ff82c3509de47a7f15fa9a14d3bf424498e3926);
    MERKLE_PROOF_P1_S1_U2[1] =
      bytes32(0x2f103524c001053f53e4c4c58cfddc1fefc8f52e956781265be2aa2da4a5f524);
    MERKLE_PROOF_P1_S1_U2[2] =
      bytes32(0x6aa495d32d929f7b132783c2fb783ea998ab2d91d5a05a177f107f6b5b23d279);

    // P1_S1_MSIG
    MERKLE_PROOF_P1_S1_MSIG = new bytes32[](2);
    MERKLE_PROOF_P1_S1_MSIG_EARLY_CLAIM = new bytes32[](2);
    MERKLE_PROOF_P1_S1_MSIG_EARLY_CLAIM[0] =
      bytes32(0xd4025b224c0acb5f5bd365443f9b54de1099b369169133262c21c52727e5d635);
    MERKLE_PROOF_P1_S1_MSIG_EARLY_CLAIM[1] =
      bytes32(0xcf9a23ce5966ce321c03a3c8311e27488542d2e6140a447a17c03e7dafa60e87);
    MERKLE_PROOF_P1_S1_MSIG[0] =
      bytes32(0xe7640362051b2b4830246311c1e24e2cb7e7c9838b8d40d146a9628303e56785);
    MERKLE_PROOF_P1_S1_MSIG[1] =
      bytes32(0xcf9a23ce5966ce321c03a3c8311e27488542d2e6140a447a17c03e7dafa60e87);

    // P2_S1_U1
    MERKLE_PROOF_P2_S1_U1 = new bytes32[](3);
    MERKLE_PROOF_P2_S1_U1_EARLY_CLAIM = new bytes32[](3);
    MERKLE_PROOF_P2_S1_U1_EARLY_CLAIM[0] =
      bytes32(0x8556a476f50816addcf2aed3aebc68fc48b2e240e21d37523ef752171e78b142);
    MERKLE_PROOF_P2_S1_U1_EARLY_CLAIM[1] =
      bytes32(0x65fab8784a80ebe11e2d2049da2b926cb6e2ba37f18a6e040bb99b11223356f0);
    MERKLE_PROOF_P2_S1_U1_EARLY_CLAIM[2] =
      bytes32(0xbe422fdf7903ba4df3898747904dc5842665f5c89c9c3b6eed9aaabad7071132);
    MERKLE_PROOF_P2_S1_U1[0] =
      bytes32(0x48c96d7deda3605137257099103936ae2e32b7a43da3ac6f96df1d303062cb3f);
    MERKLE_PROOF_P2_S1_U1[1] =
      bytes32(0x09a2d74e720fcbb7bbd19a1013722b62090e7574f4221cc9058d4329e0a28b8f);
    MERKLE_PROOF_P2_S1_U1[2] =
      bytes32(0xbe422fdf7903ba4df3898747904dc5842665f5c89c9c3b6eed9aaabad7071132);

    // P2_S1_U2
    MERKLE_PROOF_P2_S1_U2 = new bytes32[](3);
    MERKLE_PROOF_P2_S1_U2_EARLY_CLAIM = new bytes32[](2);
    MERKLE_PROOF_P2_S1_U2_EARLY_CLAIM[0] =
      bytes32(0xfb04a5d5e6b3bbfa17651971e6db88cc20504ca0d8b2ad821e225d6ba8eb295d);
    MERKLE_PROOF_P2_S1_U2_EARLY_CLAIM[1] =
      bytes32(0x5d671c0d553cbf4ab907f95ea726010a9d8f824238d0bbe5d9b75c0649dc02ef);
    MERKLE_PROOF_P2_S1_U2[0] =
      bytes32(0x721ebea913d06f4c0d0cfc479a7bcefa943e152cd496b88a3df405c2a4cd02a7);
    MERKLE_PROOF_P2_S1_U2[1] =
      bytes32(0x09a2d74e720fcbb7bbd19a1013722b62090e7574f4221cc9058d4329e0a28b8f);
    MERKLE_PROOF_P2_S1_U2[2] =
      bytes32(0xbe422fdf7903ba4df3898747904dc5842665f5c89c9c3b6eed9aaabad7071132);

    // P2_S1_MSIG
    MERKLE_PROOF_P2_S1_MSIG = new bytes32[](3);
    MERKLE_PROOF_P2_S1_MSIG_EARLY_CLAIM = new bytes32[](2);
    MERKLE_PROOF_P2_S1_MSIG_EARLY_CLAIM[0] =
      bytes32(0xe6ac58b859a427a6b6ef10bf81fab0866f54a64b307e976b071b781b180de5ab);
    MERKLE_PROOF_P2_S1_MSIG_EARLY_CLAIM[1] =
      bytes32(0x5d671c0d553cbf4ab907f95ea726010a9d8f824238d0bbe5d9b75c0649dc02ef);
    MERKLE_PROOF_P2_S1_MSIG[0] =
      bytes32(0x7889cbc626b225f885e5bd7fb9d793f7a7a896f2050094a3f28303f00e9c67b1);
    MERKLE_PROOF_P2_S1_MSIG[1] =
      bytes32(0x65fab8784a80ebe11e2d2049da2b926cb6e2ba37f18a6e040bb99b11223356f0);
    MERKLE_PROOF_P2_S1_MSIG[2] =
      bytes32(0xbe422fdf7903ba4df3898747904dc5842665f5c89c9c3b6eed9aaabad7071132);
    s_userInfo[0][0] = UserInfo({
      user: USER_1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      proof: MERKLE_PROOF_P1_S1_U1,
      proofEarly: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM
    });
    s_userInfo[0][1] = UserInfo({
      user: USER_2,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U2,
      salt: SALT_U2,
      proof: MERKLE_PROOF_P1_S1_U2,
      proofEarly: MERKLE_PROOF_P1_S1_U2_EARLY_CLAIM
    });
    s_userInfo[0][2] = UserInfo({
      user: USER_MSIG,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_MSIG,
      salt: SALT_MSIG,
      proof: MERKLE_PROOF_P1_S1_MSIG,
      proofEarly: MERKLE_PROOF_P1_S1_MSIG_EARLY_CLAIM
    });

    s_userInfo[1][0] = UserInfo({
      user: USER_1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P2_S1_U1,
      salt: SALT_U1,
      proof: MERKLE_PROOF_P2_S1_U1,
      proofEarly: MERKLE_PROOF_P2_S1_U1_EARLY_CLAIM
    });
    s_userInfo[1][1] = UserInfo({
      user: USER_2,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P2_S1_U2,
      salt: SALT_U2,
      proof: MERKLE_PROOF_P2_S1_U2,
      proofEarly: MERKLE_PROOF_P2_S1_U2_EARLY_CLAIM
    });
    s_userInfo[1][2] = UserInfo({
      user: USER_MSIG,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P2_S1_MSIG,
      salt: SALT_MSIG,
      proof: MERKLE_PROOF_P2_S1_MSIG,
      proofEarly: MERKLE_PROOF_P2_S1_MSIG_EARLY_CLAIM
    });

    vm.deal(USER_1, 10 ether);
    vm.deal(USER_2, 10 ether);
    vm.deal(USER_MSIG, 10 ether);
  }

  /// @notice Util function to convert a seed to a user
  /// @param seed The seed
  /// @return The user id
  /// @return The user address
  /// @return Whether the user is a multisig wallet
  function _seedToUser(
    uint8 seed
  ) private pure returns (uint256, address, bool) {
    uint256 id = bound(uint256(seed), 0, 2);
    return (id, id == 0 ? USER_1 : id == 1 ? USER_2 : USER_MSIG, id == 2);
  }

  /// @notice Util function to convert a seed to a season ID
  /// @param projectId The project ID
  /// @param seed The seed
  /// @return The season ID
  function _seedToSeason(uint256 projectId, uint32 seed) private view returns (uint32) {
    return uint32(bound(seed, 1, s_projectMaxSeasonId[projectId]));
  }

  /// @notice Util function to convert a seed to a project ID, BUILDClaim, and IERC20 for the
  /// project
  /// @param seed The seed
  /// @return The project ID
  /// @return The BUILDClaim contract for the project
  /// @return The IERC20 token for the project
  function _seedToProject(
    bool seed
  ) private view returns (uint256, IBUILDClaim, IERC20) {
    uint256 projectId = seed ? 2 : 1;
    IBUILDClaim targetClaim = projectId == 1 ? s_claim_1 : s_claim_2;
    IERC20 token = targetClaim.getToken();
    return (projectId, targetClaim, token);
  }

  /// @notice Util function to get the merkle root for a project
  /// @dev Each project has a different merkle root, but we use the same merkle root for all seasons
  /// of a project to avoid generating a merkle tree for each season.
  /// @param projectId The project ID
  /// @return The merkle root
  function _projectIdToMerkleRoot(
    uint256 projectId
  ) private pure returns (bytes32) {
    return projectId == 1 ? MERKLE_ROOT_P1_S1 : MERKLE_ROOT_P2_S1;
  }

  /// @notice Util function to get the minimum token amount that needs to be allocated and deposited
  /// for a project
  /// @dev The minimum token amount is the sum of the max token amounts that users can claim for a
  /// season.
  /// @param projectId The project ID
  /// @return The minimum token amount
  function _getMinTokenAmount(
    uint256 projectId
  ) private pure returns (uint256) {
    return projectId == 1 ? TOKEN_AMOUNT_P1_S1 : TOKEN_AMOUNT_P2_S1;
  }

  /// @notice Util function to skip time based on the time seed and the latest unlock start time
  /// @param timeSeed The seed to determine how much time to skip
  /// @param unlockStartTime The latest unlock start time
  function _skipTime(uint256 timeSeed, uint256 unlockStartTime) private {
    uint256 time;
    if (block.timestamp < unlockStartTime) {
      time = bound(
        timeSeed, unlockStartTime - block.timestamp, unlockStartTime + 7 days - block.timestamp
      );
      skip(time);
    } else {
      time = bound(timeSeed, 0, 1 days);
      skip(time);
    }
  }

  // added to be excluded from coverage report
  function test() public override {}
}
