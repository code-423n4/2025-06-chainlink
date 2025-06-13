// SPDX-License-Identifier: MIT
/* solhint-disable no-console */
pragma solidity 0.8.26;

import {console} from "forge-std/console.sol";
import {IAccessController} from
  "chainlink/contracts/src/v0.8/shared/interfaces/IAccessController.sol";
import {BaseScript} from "../BaseScript.s.sol";
import {BUILDFactory} from "../../src/BUILDFactory.sol";

contract DeployBUILDFactory is BaseScript {
  function run() public virtual usingBroadcast(vm.envUint("PRIVATE_KEY")) {
    console.log("Deploying BUILDFactory");
    string memory varName = "BUILD_FACTORY";
    string memory config = _loadConfigRawString("/scripts/configs/constructor_params.json");
    string memory basePath = string.concat(s_envJsonPath, ".BUILDFactory.");
    BUILDFactory.ConstructorParams memory params = BUILDFactory.ConstructorParams({
      admin: vm.envAddress("ADMIN_ADDRESS"),
      maxUnlockDuration: uint40(
        vm.parseJsonUint(config, string.concat(basePath, "max_unlock_duration"))
      ),
      maxUnlockDelay: uint40(vm.parseJsonUint(config, string.concat(basePath, "max_unlock_delay"))),
      tosAllowList: IAccessController(s_tosAllowList)
    });
    s_factory = new BUILDFactory(params);
    setVmEnvVar(varName, address(s_factory));
    addEnvVarToWrite(varName);
  }
}
