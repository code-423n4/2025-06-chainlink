// SPDX-License-Identifier: MIT
/* solhint-disable no-console */
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {EnvManager} from "./EnvManager.s.sol";
import {BUILDFactory} from "../src/BUILDFactory.sol";
import {BUILDClaim} from "../src/BUILDClaim.sol";

abstract contract BaseScript is Script, EnvManager {
  BUILDFactory internal s_factory;
  ERC20[] internal s_tokens;
  BUILDClaim[] internal s_claims;
  string internal s_envJsonPath;

  function _setEnv(
    string memory env
  ) internal override {
    s_envJsonPath = string.concat(".", env);
    super._setEnv(env);
  }

  function _loadConfigRawString(
    string memory path
  ) internal view returns (string memory) {
    string memory root = vm.projectRoot();
    return vm.readFile(string.concat(root, path));
  }

  function _getJsonArrayLength(
    string memory jsonArr
  ) internal view returns (uint256) {
    return abi.decode(vm.parseJson(jsonArr, s_envJsonPath), (bytes32[])).length;
  }

  function _getArrayIndexedItemPath(
    string memory jsonKey,
    uint256 index
  ) internal pure returns (string memory) {
    return string.concat(string.concat(jsonKey, ".["), string.concat(vm.toString(index), "]."));
  }

  modifier usingBroadcast(
    uint256 privateKey
  ) {
    console.log("Running scripts with %s as the signer", vm.addr(privateKey));
    vm.startBroadcast(privateKey);
    _;
    vm.stopBroadcast();
  }
}
