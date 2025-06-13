// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

abstract contract Constants {
  address internal constant ADMIN = address(1);
  address internal constant PAUSER = address(2);
  uint256 internal constant STRANGER_PRIVATE_KEY = 0x4;
  // address corresponding to the STRANGER_PRIVATE_KEY
  address internal constant STRANGER = 0x1efF47bc3a10a45D4B230B5d10E37751FE6AA718;

  address internal constant PROJECT_ADMIN = address(11);
  address internal constant PROJECT_ADMIN_2 = address(12);

  address internal constant NOBODY = address(101);
  address internal constant USER_1 = address(102);
  address internal constant USER_2 = address(103);
  address internal constant MSIG_DEPLOYER = address(104);
  bytes internal constant MULTISIG_WALLET_BYTECODE =
    hex"6080604052348015600f57600080fd5b506103e88061001f6000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c80632c7563831461003b578063f8a8fd6d1461006b575b600080fd5b610055600480360381019061005091906102ac565b610075565b604051610062919061032a565b60405180910390f35b6100736100ba565b005b6000806109c45a610086919061037e565b905082156100a1576000808551602087018885f491506100b2565b60008085516020870160008986f191505b509392505050565b565b6000604051905090565b600080fd5b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b60006100fb826100d0565b9050919050565b61010b816100f0565b811461011657600080fd5b50565b60008135905061012881610102565b92915050565b600080fd5b600080fd5b6000601f19601f8301169050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b61018182610138565b810181811067ffffffffffffffff821117156101a05761019f610149565b5b80604052505050565b60006101b36100bc565b90506101bf8282610178565b919050565b600067ffffffffffffffff8211156101df576101de610149565b5b6101e882610138565b9050602081019050919050565b82818337600083830152505050565b6000610217610212846101c4565b6101a9565b90508281526020810184848401111561023357610232610133565b5b61023e8482856101f5565b509392505050565b600082601f83011261025b5761025a61012e565b5b813561026b848260208601610204565b91505092915050565b60008115159050919050565b61028981610274565b811461029457600080fd5b50565b6000813590506102a681610280565b92915050565b6000806000606084860312156102c5576102c46100c6565b5b60006102d386828701610119565b935050602084013567ffffffffffffffff8111156102f4576102f36100cb565b5b61030086828701610246565b925050604061031186828701610297565b9150509250925092565b61032481610274565b82525050565b600060208201905061033f600083018461031b565b92915050565b6000819050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b600061038982610345565b915061039483610345565b92508282039050818111156103ac576103ab61034f565b5b9291505056fea264697066735822122016092f14a9f048cb1973a24f428ccd4ae46f7d017303d23019cfcb25773a66b464736f6c63430008190033";
  bytes32 internal constant MULTISIG_WALLET_SALT =
    0x7465737400000000000000000000000000000000000000000000000000000000;
  address internal constant USER_MSIG = 0x473f183bE3127ECC34d3E503AEc3B6b8a6A4CCe4;

  // The following are hypothetical values for testing purposes to validate the underlying
  // calculations.
  // Different values will be used at launch
  uint256 internal constant MAX_TOKEN_AMOUNT_P1_S1_U1 = 10 * 1e18; // project 1, season 1, user 1
  uint256 internal constant MAX_TOKEN_AMOUNT_P1_S1_U2 = 90 * 1e18; // project 1, season 1, user 2
  uint256 internal constant MAX_TOKEN_AMOUNT_P1_S1_MSIG = 50 * 1e18; // project 1, season 1, msig
  uint256 internal constant MAX_TOKEN_AMOUNT_P1_S2_U1 = 70 * 1e18; // project 1, season 2, user 1
  uint256 internal constant MAX_TOKEN_AMOUNT_P1_S2_U2 = 130 * 1e18; // project 1, season 2, user 2
  uint256 internal constant MAX_TOKEN_AMOUNT_P1_S2_MSIG = 100 * 1e18; // project 1, season 2, msig
  uint256 internal constant MAX_TOKEN_AMOUNT_P2_S1_U1 = 55 * 1e6; // project 2, season 1, user 1
  uint256 internal constant MAX_TOKEN_AMOUNT_P2_S1_U2 = 12 * 1e6; // project 2, season 1, user 2
  uint256 internal constant MAX_TOKEN_AMOUNT_P2_S1_MSIG = 100 * 1e6; // project 2, season 1, msig

  uint256 internal constant SALT_U1 = 1;
  uint256 internal constant SALT_U2 = 2;
  uint256 internal constant SALT_MSIG = 3;

  bytes32 internal constant MERKLE_ROOT_P1_S1 =
    0x505c27a5c69f9353daeb95f6ca1764a6046aa25020c88229acd4bcbf8845521f;
  bytes32 internal constant MERKLE_ROOT_P1_S2 =
    0xdf4ff36abb8935f98e023f58d0f96cf87b62f4ad7e49ee3c4de5fc208ae2303f;
  bytes32 internal constant MERKLE_ROOT_P2_S1 =
    0x18558b1a22179a8ae424e5f6f457952c661e5c14c7497295ce6f49e4ea330107;

  /* solhint-disable chainlink-solidity/prefix-storage-variables-with-s-underscore */
  bytes32[] internal MERKLE_PROOF_P1_S1_U1;
  bytes32[] internal MERKLE_PROOF_P1_S1_U1_EARLY_CLAIM;
  bytes32[] internal MERKLE_PROOF_P1_S1_U2;
  bytes32[] internal MERKLE_PROOF_P1_S1_U2_EARLY_CLAIM;
  bytes32[] internal MERKLE_PROOF_P1_S1_MSIG;
  bytes32[] internal MERKLE_PROOF_P1_S1_MSIG_EARLY_CLAIM;
  bytes32[] internal MERKLE_PROOF_P1_S2_U1;
  bytes32[] internal MERKLE_PROOF_P1_S2_U1_EARLY_CLAIM;
  bytes32[] internal MERKLE_PROOF_P1_S2_U2;
  bytes32[] internal MERKLE_PROOF_P1_S2_U2_EARLY_CLAIM;
  bytes32[] internal MERKLE_PROOF_P1_S2_MSIG;
  bytes32[] internal MERKLE_PROOF_P1_S2_MSIG_EARLY_CLAIM;
  bytes32[] internal MERKLE_PROOF_P2_S1_U1;
  bytes32[] internal MERKLE_PROOF_P2_S1_U1_EARLY_CLAIM;
  bytes32[] internal MERKLE_PROOF_P2_S1_U2;
  bytes32[] internal MERKLE_PROOF_P2_S1_U2_EARLY_CLAIM;
  bytes32[] internal MERKLE_PROOF_P2_S1_MSIG;
  bytes32[] internal MERKLE_PROOF_P2_S1_MSIG_EARLY_CLAIM;

  uint40 internal constant MAX_UNLOCK_DURATION = 4 * 365 days;
  uint40 internal constant MAX_UNLOCK_DELAY = 4 * 365 days;

  string internal constant PROJECT_NAME_1 = "FOO";
  uint8 internal constant PROJECT_DECIMALS_1 = 18;
  string internal constant PROJECT_NAME_2 = "BAR";
  uint8 internal constant PROJECT_DECIMALS_2 = 6;
  uint32 internal constant SEASON_ID_S1 = 1;
  uint40 internal constant UNLOCK_START_TIME_S1 = 1 days;
  uint40 internal constant UNLOCK_DELAY_P1_S1 = 7 days;
  uint40 internal constant UNLOCK_DELAY_P2_S1 = 5 days;
  uint40 internal constant UNLOCK_DURATION_S1 = 30 days;
  uint256 internal constant TOKEN_AMOUNT_P1_S1 = 150 ether;
  uint256 internal constant TOKEN_AMOUNT_P2_S1 = 167_000_000;
  uint16 internal constant BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1 = 1000; // 10%
  uint16 internal constant BASE_TOKEN_CLAIM_PERCENTAGE_P2_S1 = 500; // 5%
  uint16 internal constant MAX_BASE_TOKEN_CLAIM_PERCENTAGE = 10000; // 100%
  uint16 internal constant EARLY_VEST_RATIO_MIN_P1_S1 = 1000;
  uint16 internal constant EARLY_VEST_RATIO_MAX_P1_S1 = 9000;

  uint32 internal constant SEASON_ID_S2 = 2;
  uint40 internal constant UNLOCK_START_TIME_S2 = 31 days;
  uint40 internal constant UNLOCK_DELAY_P1_S2 = 0;
  uint40 internal constant UNLOCK_DELAY_P2_S2 = 3 days;
  uint40 internal constant UNLOCK_DURATION_S2 = 60 days;
  uint256 internal constant TOKEN_AMOUNT_P1_S2 = 300 ether;
  uint16 internal constant BASE_TOKEN_CLAIM_PERCENTAGE_P1_S2 = 1500; // 15%
  uint16 internal constant EARLY_VEST_RATIO_MIN_P1_S2 = 2000;
  uint16 internal constant EARLY_VEST_RATIO_MAX_P1_S2 = 8000;

  // magic numbers for reward claims
  // base formula:
  // base + unlocked + early =
  // baseClaim% + (1-baseClaim%)*(unlock%) +
  // (1-baseClaim%)*(1-unlock%)*((maxRatio - minRatio)*unlock%+minRatio)
  //
  // 10% + (90%)(0%) + (90%)(100%)(80%*0%+10%) = 10% + 0% + 90%*10% = 19%
  uint256 internal constant EARLY_CLAIM_START_P1_S1_U1 = MAX_TOKEN_AMOUNT_P1_S1_U1 * 1900 / 10000;
  uint256 internal constant EARLY_CLAIM_START_P1_S1_U2 = MAX_TOKEN_AMOUNT_P1_S1_U2 * 1900 / 10000;
  uint256 internal constant EARLY_CLAIM_START_P1_S1_MSIG =
    MAX_TOKEN_AMOUNT_P1_S1_MSIG * 1900 / 10000;
  // 15% + (85%)(0%) + (85%)(100%)(60%*0%+20%) = 15% + 0% + 85%*20% = 32%
  uint256 internal constant EARLY_CLAIM_START_P1_S2_U1 = MAX_TOKEN_AMOUNT_P1_S2_U1 * 3200 / 10000;
  // 10% + (90%)(50%) + (90%)(50%)(80%*50%+10%) = 10% + 45% + 45%*50% = 77.5%
  uint256 internal constant EARLY_CLAIM_HALF_P1_S1_U1 = MAX_TOKEN_AMOUNT_P1_S1_U1 * 7750 / 10000;
  uint256 internal constant EARLY_CLAIM_HALF_P1_S1_MSIG = MAX_TOKEN_AMOUNT_P1_S1_MSIG * 7750 / 10000;
  // 15% + (85%)(50%) + (85%)(50%)(60%*50%+20%) = 15% + 42.5% + 42.5%*50% = 78.75%
  uint256 internal constant EARLY_CLAIM_HALF_P1_S2_U2 = MAX_TOKEN_AMOUNT_P1_S2_U2 * 7875 / 10000;
  // 10% + (90%)(0%) = 10%
  uint256 internal constant CLAIM_START_P1_S1_U1 =
    MAX_TOKEN_AMOUNT_P1_S1_U1 * BASE_TOKEN_CLAIM_PERCENTAGE_P1_S1 / 10000;
  uint256 internal constant CLAIM_START_P1_S2_U1 =
    MAX_TOKEN_AMOUNT_P1_S2_U1 * BASE_TOKEN_CLAIM_PERCENTAGE_P1_S2 / 10000;
  // 10% + (90%)(50%) = 10% + 45% = 55%
  uint256 internal constant CLAIM_HALF_P1_S1_U1 = MAX_TOKEN_AMOUNT_P1_S1_U1 * 5500 / 10000;
  uint256 internal constant CLAIM_HALF_P1_S1_U2 = MAX_TOKEN_AMOUNT_P1_S1_U2 * 5500 / 10000;
  uint256 internal constant CLAIM_HALF_P1_S1_MSIG = MAX_TOKEN_AMOUNT_P1_S1_MSIG * 5500 / 10000;
  // 5% + (95%)(17/30) = 5% + 53.833333% = 58.833333%
  uint256 internal constant CLAIM_HALF_P2_S1_U1 = MAX_TOKEN_AMOUNT_P2_S1_U1 * 58833333 / 100000000;
  uint256 internal constant CLAIM_HALF_P2_S1_U2 = MAX_TOKEN_AMOUNT_P2_S1_U2 * 58833333 / 100000000;
  uint256 internal constant CLAIM_HALF_P2_S1_MSIG =
    MAX_TOKEN_AMOUNT_P2_S1_MSIG * 58833333 / 100000000;
}
