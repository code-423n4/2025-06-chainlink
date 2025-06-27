// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IDelegateRegistry} from "@delegatexyz/delegate-registry/v2.0/src/IDelegateRegistry.sol";
import {DelegateRegistry} from "@delegatexyz/delegate-registry/v2.0/src/DelegateRegistry.sol";
import {Constants} from "./Constants.t.sol";
import {Test} from "forge-std/Test.sol";
import {IBUILDClaim} from "../src/interfaces/IBUILDClaim.sol";
import {IBUILDFactory} from "../src/interfaces/IBUILDFactory.sol";
import {BUILDFactory} from "../src/BUILDFactory.sol";
import {Multicall3} from "../src/mocks/Multicall3.sol";
import {MultiSendCallOnly} from "../src/mocks/MultiSendCallOnly.sol";
import {MultisigWallet} from "../src/mocks/MultisigWallet.sol";
import {ERC20Token} from "../src/mocks/ERC20Token.sol";
import {FeeOnTransferERC20Token} from "../src/mocks/FeeOnTransferERC20Token.sol";
import {InvalidTransferERC20Token} from "../src/mocks/InvalidTransferERC20Token.sol";
import {ReentrantERC20Token} from "../src/mocks/ReentrantERC20Token.sol";
import {Utils} from "./Utils.t.sol";

contract BaseTest is Constants, Test, Utils {
  BUILDFactory internal s_factory;
  ERC20 internal s_token;
  ERC20 internal s_token_2;
  ReentrantERC20Token internal s_token_reentrant;
  FeeOnTransferERC20Token internal s_token_feeOnTransfer;
  InvalidTransferERC20Token internal s_token_invalidTransfer;
  IBUILDClaim internal s_claim;
  IBUILDClaim internal s_claim_2;
  IBUILDClaim internal s_claim_reentrant;
  IBUILDClaim internal s_claim_feeOnTransfer;
  IBUILDClaim internal s_claim_invalidTransfer;
  Multicall3 internal s_multicall;
  MultiSendCallOnly internal s_multiSendCallOnly;
  MultisigWallet internal s_multisigWallet;
  DelegateRegistry internal s_delegateRegistry;

  constructor() {
    vm.label(ADMIN, "ADMIN");
    vm.label(NOBODY, "NOBODY");
    vm.label(PROJECT_ADMIN, "PROJECT_ADMIN");
    vm.label(STRANGER, "STRANGER");

    vm.startPrank(ADMIN);
    s_delegateRegistry = new DelegateRegistry();
    BUILDFactory.ConstructorParams memory params = BUILDFactory.ConstructorParams({
      admin: ADMIN,
      maxUnlockDuration: MAX_UNLOCK_DURATION,
      maxUnlockDelay: MAX_UNLOCK_DELAY,
      delegateRegistry: IDelegateRegistry(s_delegateRegistry)
    });
    s_factory = new BUILDFactory(params);
    s_multicall = new Multicall3();
    s_multiSendCallOnly = new MultiSendCallOnly();

    _changePrankTxOrigin(MSIG_DEPLOYER);
    bytes memory bytecode = MULTISIG_WALLET_BYTECODE;
    address msigAddr;
    assembly {
      msigAddr := create2(callvalue(), add(bytecode, 0x20), mload(bytecode), MULTISIG_WALLET_SALT)
      if iszero(extcodesize(msigAddr)) { revert(0, 0) }
    }
    s_multisigWallet = MultisigWallet(msigAddr);
    vm.label(address(s_multisigWallet), "MultisigWallet");

    _changePrank(PROJECT_ADMIN);
    s_token =
      new ERC20Token({name: PROJECT_NAME_1, symbol: PROJECT_NAME_1, decimals: PROJECT_DECIMALS_1});
    s_token_2 =
      new ERC20Token({name: PROJECT_NAME_2, symbol: PROJECT_NAME_2, decimals: PROJECT_DECIMALS_2});

    vm.label(address(s_factory), "BUILDFactory");
    vm.label(address(s_token), "ProjectToken");
    vm.label(address(s_token_2), "ProjectToken2");

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

    // P1_S2_U1
    MERKLE_PROOF_P1_S2_U1 = new bytes32[](3);
    MERKLE_PROOF_P1_S2_U1_EARLY_CLAIM = new bytes32[](3);
    MERKLE_PROOF_P1_S2_U1_EARLY_CLAIM[0] =
      bytes32(0xa5a994ee9bdd2f1f4285a88ef1cca240593c1226413d274976915fba8ade19e8);
    MERKLE_PROOF_P1_S2_U1_EARLY_CLAIM[1] =
      bytes32(0x77f42ae25e9d001272843175bb437568c2ee35ac8408d8976dc1ea2316757c19);
    MERKLE_PROOF_P1_S2_U1_EARLY_CLAIM[2] =
      bytes32(0x66727c936d57ba2c125a526b37e89dbb7eaa912442a30243f73b1ecc7587ad43);
    MERKLE_PROOF_P1_S2_U1[0] =
      bytes32(0x1988c7606ca1a20e10c0e13da00f60991c8454a0a2644ae173257bff2396a6f4);
    MERKLE_PROOF_P1_S2_U1[1] =
      bytes32(0x413d654a3796652f1a685ef20f3b4a89323dc947cda28f6b58d2645f45a5f7a4);
    MERKLE_PROOF_P1_S2_U1[2] =
      bytes32(0x66727c936d57ba2c125a526b37e89dbb7eaa912442a30243f73b1ecc7587ad43);

    // P1_S2_U2
    MERKLE_PROOF_P1_S2_U2 = new bytes32[](3);
    MERKLE_PROOF_P1_S2_U2_EARLY_CLAIM = new bytes32[](2);
    MERKLE_PROOF_P1_S2_U2_EARLY_CLAIM[0] =
      bytes32(0xb0f0268e70cdf0b9e9d1d752afdf49219db572d0ce18aec10052c77a83b597f3);
    MERKLE_PROOF_P1_S2_U2_EARLY_CLAIM[1] =
      bytes32(0x0c740f0768cbeab5394d387d11e9b93289ead261749c430fb2bd7b3634554ba9);
    MERKLE_PROOF_P1_S2_U2[0] =
      bytes32(0x10dc4269e39553bf5a523b51ffa4c438c1907eeabfac3d1b25db82f14e4dab52);
    MERKLE_PROOF_P1_S2_U2[1] =
      bytes32(0x413d654a3796652f1a685ef20f3b4a89323dc947cda28f6b58d2645f45a5f7a4);
    MERKLE_PROOF_P1_S2_U2[2] =
      bytes32(0x66727c936d57ba2c125a526b37e89dbb7eaa912442a30243f73b1ecc7587ad43);

    // P1_S2_MSIG
    MERKLE_PROOF_P1_S2_MSIG = new bytes32[](3);
    MERKLE_PROOF_P1_S2_MSIG_EARLY_CLAIM = new bytes32[](2);
    MERKLE_PROOF_P1_S2_MSIG_EARLY_CLAIM[0] =
      bytes32(0xa7cab3029a1520e4944e74e08066d26a4149485f07cc3ec2ab00f941a0de0b8b);
    MERKLE_PROOF_P1_S2_MSIG_EARLY_CLAIM[1] =
      bytes32(0x0c740f0768cbeab5394d387d11e9b93289ead261749c430fb2bd7b3634554ba9);
    MERKLE_PROOF_P1_S2_MSIG[0] =
      bytes32(0x9fc25daf39a73a8ade94847450af72325633906c801a776ab4fbf5ff404a9947);
    MERKLE_PROOF_P1_S2_MSIG[1] =
      bytes32(0x77f42ae25e9d001272843175bb437568c2ee35ac8408d8976dc1ea2316757c19);
    MERKLE_PROOF_P1_S2_MSIG[2] =
      bytes32(0x66727c936d57ba2c125a526b37e89dbb7eaa912442a30243f73b1ecc7587ad43);

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
  }

  modifier whenProjectAdded() {
    _changePrank(ADMIN);
    IBUILDFactory.AddProjectParams[] memory input = new IBUILDFactory.AddProjectParams[](1);
    input[0] = IBUILDFactory.AddProjectParams({token: address(s_token), admin: PROJECT_ADMIN});
    s_factory.addProjects(input);
    _;
  }

  modifier whenProjectAddedAndClaimDeployed() {
    _changePrank(ADMIN);
    IBUILDFactory.AddProjectParams[] memory input = new IBUILDFactory.AddProjectParams[](1);
    input[0] = IBUILDFactory.AddProjectParams({token: address(s_token), admin: PROJECT_ADMIN});
    s_factory.addProjects(input);

    _changePrank(PROJECT_ADMIN);
    s_claim = s_factory.deployClaim(address(s_token));
    vm.label(address(s_claim), "BUILDClaim");
    _;
  }

  modifier whenProject2AddedAndClaimDeployed() {
    _changePrank(ADMIN);
    IBUILDFactory.AddProjectParams[] memory input = new IBUILDFactory.AddProjectParams[](1);
    input[0] = IBUILDFactory.AddProjectParams({token: address(s_token_2), admin: PROJECT_ADMIN});
    s_factory.addProjects(input);

    _changePrank(PROJECT_ADMIN);
    s_claim_2 = s_factory.deployClaim(address(s_token_2));
    _;
  }

  modifier whenReentrantProjectAddedAndClaimDeployed() {
    _changePrank(ADMIN);
    s_token_reentrant = new ReentrantERC20Token("ReentrantToken", "RET", 18);
    address projectAdmin = address(s_token_reentrant); // to bypass the onlyProjectAdmin modifier
    s_token_reentrant.disableReentrancy();
    s_token_reentrant.transfer(projectAdmin, TOKEN_AMOUNT_P1_S1 + TOKEN_AMOUNT_P1_S2);

    IBUILDFactory.AddProjectParams[] memory input = new IBUILDFactory.AddProjectParams[](1);
    input[0] =
      IBUILDFactory.AddProjectParams({token: address(s_token_reentrant), admin: projectAdmin});
    s_factory.addProjects(input);

    _changePrank(projectAdmin);
    s_claim_reentrant = s_factory.deployClaim(address(s_token_reentrant));
    s_token_reentrant.approve(address(s_claim_reentrant), TOKEN_AMOUNT_P1_S1 + TOKEN_AMOUNT_P1_S2);
    _;
  }

  modifier whenFeeOnTransferProjectAddedAndClaimDeployed() {
    _changePrank(PROJECT_ADMIN);
    s_token_feeOnTransfer = new FeeOnTransferERC20Token(18);

    _changePrank(ADMIN);
    IBUILDFactory.AddProjectParams[] memory input = new IBUILDFactory.AddProjectParams[](1);
    input[0] =
      IBUILDFactory.AddProjectParams({token: address(s_token_feeOnTransfer), admin: PROJECT_ADMIN});
    s_factory.addProjects(input);

    _changePrank(PROJECT_ADMIN);
    s_claim_feeOnTransfer = s_factory.deployClaim(address(s_token_feeOnTransfer));
    s_token_feeOnTransfer.approve(
      address(s_claim_feeOnTransfer), TOKEN_AMOUNT_P1_S1 + TOKEN_AMOUNT_P1_S2
    );
    _;
  }

  modifier whenInvalidTransferProjectAddedAndClaimDeployed() {
    _changePrank(PROJECT_ADMIN);
    s_token_invalidTransfer = new InvalidTransferERC20Token(18);

    _changePrank(ADMIN);
    IBUILDFactory.AddProjectParams[] memory input = new IBUILDFactory.AddProjectParams[](1);
    input[0] = IBUILDFactory.AddProjectParams({
      token: address(s_token_invalidTransfer),
      admin: PROJECT_ADMIN
    });
    s_factory.addProjects(input);

    _changePrank(PROJECT_ADMIN);
    s_claim_invalidTransfer = s_factory.deployClaim(address(s_token_invalidTransfer));
    s_token_invalidTransfer.approve(
      address(s_claim_invalidTransfer), TOKEN_AMOUNT_P1_S1 + TOKEN_AMOUNT_P1_S2
    );
    _;
  }

  modifier whenASeasonConfigIsSetForTheSeason() {
    _changePrank(ADMIN);
    uint256 unlockStartsAt = block.timestamp + UNLOCK_START_TIME_S1;
    s_factory.setSeasonUnlockStartTime(SEASON_ID_S1, unlockStartsAt);
    _;
  }

  modifier whenASeason2ConfigIsSetForTheSeason() {
    _changePrank(ADMIN);
    uint256 unlockStartsAt = uint256(block.timestamp) + UNLOCK_START_TIME_S2;
    s_factory.setSeasonUnlockStartTime(SEASON_ID_S2, unlockStartsAt);
    _;
  }

  modifier whenASeasonConfigIsSetForTheProject() {
    _changePrank(ADMIN);
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
    _;
  }

  modifier whenASeason2ConfigIsSetForTheProject() {
    _changePrank(ADMIN);
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
    _;
  }

  modifier whenTokensAreDepositedForTheProject() {
    _changePrank(PROJECT_ADMIN);
    uint256 totalTokenAmount = TOKEN_AMOUNT_P1_S1 + TOKEN_AMOUNT_P1_S2;
    s_token.approve(address(s_claim), totalTokenAmount);
    s_claim.deposit(totalTokenAmount);
    _;
  }

  modifier whenTheUnlockDelayIsActiveForSeason1() {
    skip(UNLOCK_START_TIME_S1 + UNLOCK_DELAY_P1_S1 - 1);
    _;
  }

  modifier whenTheUnlockDelayHasEndedForSeason1() {
    skip(UNLOCK_START_TIME_S1 + UNLOCK_DELAY_P1_S1);
    _;
  }

  modifier whenTheUnlockDelayHasEndedForSeason2() {
    skip(UNLOCK_START_TIME_S2 + UNLOCK_DELAY_P1_S2);
    _;
  }

  modifier whenTheUnlockHasStartedForSeason1() {
    skip(UNLOCK_START_TIME_S1 + 1);
    _;
  }

  modifier whenTheUnlockIsInHalfWayForSeason1() {
    _skipUnlockHalfwayForSeason1();
    _;
  }

  function _skipUnlockHalfwayForSeason1() internal {
    skip(UNLOCK_START_TIME_S1 + UNLOCK_DELAY_P1_S1 + (UNLOCK_DURATION_S1 / 2));
  }

  modifier whenTheUnlockEndedForProject1Season1() {
    _skipUnlockEndedForSeason1();
    _;
  }

  function _skipUnlockEndedForSeason1() internal {
    skip(UNLOCK_START_TIME_S1 + UNLOCK_DELAY_P1_S1 + UNLOCK_DURATION_S1 + 1);
  }

  modifier whenTheUnlockIsInHalfWayForSeason2() {
    _skipUnlockHalfwayForSeason2();
    _;
  }

  function _skipUnlockHalfwayForSeason2() internal {
    skip(UNLOCK_START_TIME_S2 + UNLOCK_DELAY_P1_S2 + (UNLOCK_DURATION_S2 / 2));
  }

  modifier whenTheUnlockEndedForProject1Season2() {
    _skipUnlockEndedForSeason2();
    _;
  }

  function _skipUnlockEndedForSeason2() internal {
    skip(UNLOCK_START_TIME_S2 + UNLOCK_DELAY_P1_S2 + UNLOCK_DURATION_S2 + 1);
  }

  modifier whenTheUserClaimedTheUnlockedTokens() {
    _changePrank(USER_1);
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: false
    });
    s_claim.claim(USER_1, params);
    _;
  }

  modifier whenTheUserEarlyClaimed() {
    _changePrank(USER_1);
    IBUILDClaim.ClaimParams[] memory params = new IBUILDClaim.ClaimParams[](1);
    params[0] = IBUILDClaim.ClaimParams({
      seasonId: SEASON_ID_S1,
      proof: MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM,
      maxTokenAmount: MAX_TOKEN_AMOUNT_P1_S1_U1,
      salt: SALT_U1,
      isEarlyClaim: true
    });
    s_claim.claim(USER_1, params);
    _;
  }

  modifier whenUserHasDelegated(address user, address delegateTo, address contract_) {
    _delegateUser(user, delegateTo, contract_);
    _changePrank(delegateTo);
    _;
  }

  function _delegateUser(address user, address delegateTo, address contract_) internal {
    _changePrank(user);
    s_delegateRegistry.delegateContract({
      to: delegateTo,
      contract_: contract_,
      rights: bytes32(0),
      enable: true
    });
  }

  modifier whenProject2AddedAndClaimDeployedAndConfigured() {
    _changePrank(ADMIN);
    IBUILDFactory.AddProjectParams[] memory input = new IBUILDFactory.AddProjectParams[](1);
    input[0] = IBUILDFactory.AddProjectParams({token: address(s_token_2), admin: PROJECT_ADMIN});
    s_factory.addProjects(input);

    _changePrank(PROJECT_ADMIN);
    s_claim_2 = s_factory.deployClaim(address(s_token_2));
    vm.label(address(s_claim_2), "BUILDClaim2");

    s_token_2.approve(address(s_claim_2), TOKEN_AMOUNT_P2_S1);
    s_claim_2.deposit(TOKEN_AMOUNT_P2_S1);

    _changePrank(ADMIN);
    IBUILDFactory.SetProjectSeasonParams[] memory params =
      new IBUILDFactory.SetProjectSeasonParams[](1);
    params[0] = IBUILDFactory.SetProjectSeasonParams({
      token: address(s_token_2),
      seasonId: SEASON_ID_S1,
      config: IBUILDFactory.ProjectSeasonConfig({
        tokenAmount: TOKEN_AMOUNT_P2_S1,
        baseTokenClaimBps: BASE_TOKEN_CLAIM_PERCENTAGE_P2_S1,
        unlockDelay: UNLOCK_DELAY_P2_S1,
        unlockDuration: UNLOCK_DURATION_S1,
        merkleRoot: MERKLE_ROOT_P2_S1,
        earlyVestRatioMinBps: EARLY_VEST_RATIO_MIN_P1_S1,
        earlyVestRatioMaxBps: EARLY_VEST_RATIO_MAX_P1_S1,
        isRefunding: false
      })
    });
    s_factory.setProjectSeasonConfig(params);
    _;
  }

  modifier whenPauserHasFactoryPauserRole(
    address pauser
  ) {
    _changePrank(ADMIN);
    s_factory.grantRole(s_factory.PAUSER_ROLE(), pauser);
    vm.label(pauser, "PAUSER");
    _;
  }

  modifier whenFactoryPaused(
    address pauser
  ) {
    _changePrank(ADMIN);
    s_factory.grantRole(s_factory.PAUSER_ROLE(), pauser);
    vm.label(pauser, "PAUSER");
    _changePrank(pauser);
    s_factory.emergencyPause();
    _;
  }

  modifier whenClaimPaused(address pauser, address token) {
    _changePrank(ADMIN);
    s_factory.grantRole(s_factory.PAUSER_ROLE(), pauser);
    vm.label(pauser, "PAUSER");
    _changePrank(pauser);
    s_factory.pauseClaimContract(token);
    _;
  }

  modifier whenFactoryClosed() {
    _changePrank(ADMIN);
    s_factory.close();
    _;
  }

  modifier whenProjectSeasonIsRefunding() {
    _refundP1(SEASON_ID_S1);
    _;
  }

  function _refundP1(
    uint256 season
  ) internal {
    _changePrank(ADMIN);
    s_factory.startRefund(address(s_token), season);
  }

  modifier whenThereIsPendingAdminTransfer() {
    _changePrank(ADMIN);
    s_factory.beginDefaultAdminTransfer(NOBODY);
    _;
  }

  modifier whenSeason1IsSetup() {
    _setupSeason1();
    _;
  }

  function _setupSeason1()
    internal
    whenASeasonConfigIsSetForTheSeason
    whenProjectAddedAndClaimDeployed
    whenTokensAreDepositedForTheProject
    whenASeasonConfigIsSetForTheProject
  {}

  modifier whenSeason2IsSetup() {
    _setupSeason2();
    _;
  }

  function _setupSeason2()
    internal
    whenASeason2ConfigIsSetForTheSeason
    whenASeason2ConfigIsSetForTheProject
  {}

  function _getUsers() internal pure returns (address[] memory) {
    address[] memory users = new address[](3);
    users[0] = USER_1;
    users[1] = USER_2;
    users[2] = USER_MSIG;
    return users;
  }

  function _getSeasons() internal pure returns (uint32[] memory) {
    uint32[] memory seasons = new uint32[](2);
    seasons[0] = SEASON_ID_S1;
    seasons[1] = SEASON_ID_S2;
    return seasons;
  }

  function _calculateLoyalty(
    uint256 tokens,
    uint256 share,
    uint256 pool
  ) internal pure returns (uint256) {
    return tokens * share / pool;
  }

  // note: this should only be used when there are no early claims involved
  function _emitClaimedNoEarlyClaim(
    address user,
    uint256 season,
    uint256 amount,
    uint256 userClaimedInSeason,
    uint256 totalClaimedInSeason
  ) internal {
    emit IBUILDClaim.Claimed(
      user, season, amount, false, 0, userClaimedInSeason, totalClaimedInSeason, 0, 0
    );
  }

  // add this to be excluded from coverage report
  function test() public virtual override {}
}
