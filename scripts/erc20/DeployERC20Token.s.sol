// SPDX-License-Identifier: MIT
/* solhint-disable no-console */
pragma solidity 0.8.26;

import {console} from "forge-std/console.sol";
import {BaseScript} from "../BaseScript.s.sol";
import {ERC20Token} from "../../src/mocks/ERC20Token.sol";

contract DeployERC20Token is BaseScript {
  function run() public virtual usingBroadcast(vm.envUint("PRIVATE_KEY")) {
    string memory varNamePrefix = "ERC20_TOKEN_";
    string memory projectConfigs = _loadConfigRawString("/scripts/configs/projects.json");
    uint256 numProjects = _getJsonArrayLength(projectConfigs);
    for (uint256 i; i < numProjects; ++i) {
      console.log("Deploying ERC20Token %s", i);
      string memory path = _getArrayIndexedItemPath(s_envJsonPath, i);
      ERC20Token token = new ERC20Token({
        name: vm.parseJsonString(projectConfigs, string.concat(path, "name")),
        symbol: vm.parseJsonString(projectConfigs, string.concat(path, "symbol")),
        decimals: uint8(vm.parseJsonUint(projectConfigs, string.concat(path, "decimals")))
      });
      s_tokens.push(token);
      string memory varName = string.concat(varNamePrefix, vm.toString(i));
      setVmEnvVar(varName, address(token));
      addEnvVarToWrite(varName);
    }
  }
}
