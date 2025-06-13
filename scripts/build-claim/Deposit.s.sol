// SPDX-License-Identifier: MIT
/* solhint-disable no-console */
pragma solidity 0.8.26;

import {console} from "forge-std/console.sol";
import {BaseScript} from "../BaseScript.s.sol";

contract Deposit is BaseScript {
  function run() public virtual usingBroadcast(vm.envUint("PRIVATE_KEY")) {
    string memory projectSeasonConfigs =
      _loadConfigRawString("/scripts/configs/project_seasons.json");
    uint256 numProjectSeasons = _getJsonArrayLength(projectSeasonConfigs);
    for (uint256 i; i < numProjectSeasons; ++i) {
      console.log("Depositing tokens in a BUILDClaim %s", i);
      string memory path = _getArrayIndexedItemPath(s_envJsonPath, i);
      uint256 projectIndex =
        vm.parseJsonUint(projectSeasonConfigs, string.concat(path, "project_index"));
      uint256 amount = vm.parseJsonUint(projectSeasonConfigs, string.concat(path, "token_amount"));
      s_tokens[projectIndex].approve({spender: address(s_claims[projectIndex]), value: amount});
      s_claims[projectIndex].deposit(amount);
    }
  }
}
