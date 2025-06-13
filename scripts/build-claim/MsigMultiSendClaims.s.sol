// forge script scripts/build-claim/MsigMultiSendClaims.s.sol:MsigMultiSendClaims
// --broadcast -vvvv --rpc-url $SEPOLIA_RPC_URL
// Testnet Msig address: 0x5eb09150027C66fAd2ec633BC75Da518EC0992C2

// SPDX-License-Identifier: MIT
/* solhint-disable no-console */
pragma solidity 0.8.26;

import {console} from "forge-std/console.sol";
import {BaseScript} from "../BaseScript.s.sol";
import {IBUILDClaim} from "../../src/interfaces/IBUILDClaim.sol";

contract MsigMultiSendClaims is BaseScript {
  string private constant ENV = "SEPOLIA";

  constructor() {
    _setEnv(ENV);
    checkVars();
    setVars();
  }

  function run() public virtual usingBroadcast(vm.envUint("PRIVATE_KEY")) {
    console.log("Generating data for a MultiSend claim transaction");
    string memory config = _loadConfigRawString("/scripts/configs/msig_multisend_claims.json");
    uint256 numClaims = _getJsonArrayLength(config);
    for (uint256 i; i < numClaims; ++i) {
      string memory path = _getArrayIndexedItemPath(s_envJsonPath, i);
      uint256 seasonId = vm.parseJsonUint(config, string.concat(path, ".season_id"));
      uint256 maxTokenAmount = vm.parseJsonUint(config, string.concat(path, ".max_token_amount"));
      uint256 salt = vm.parseJsonUint(config, string.concat(path, ".salt"));
      bytes32[] memory proof =
        vm.parseJsonBytes32Array(config, string.concat(path, ".merkle_proof"));
      IBUILDClaim.ClaimParams[] memory claimParams = new IBUILDClaim.ClaimParams[](1);
      claimParams[0] = IBUILDClaim.ClaimParams({
        seasonId: seasonId,
        proof: proof,
        maxTokenAmount: maxTokenAmount,
        salt: salt,
        isEarlyClaim: false
      });
      bytes memory data = abi.encodeWithSignature(
        "claim(address,(uint256,bytes32[],uint256,uint256,bool)[])",
        vm.addr(vm.envUint("PRIVATE_KEY")),
        claimParams
      );
      console.log("Data %s:", i);
      console.logBytes(data);
    }
    console.log(
      "Go to the Gnosis safe website, click on Transaction Builder, and enter the above data"
    );
  }
}
