// SPDX-License-Identifier: MIT
/* solhint-disable no-console */
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";

contract EnvManager is Script {
  string internal s_env; // SEPOLIA
  string[] internal s_requiredEnvVars = ["ADMIN_ADDRESS", "PRIVATE_KEY", "RPC_URL", "TOS_SIGNER"];
  string[] internal s_envVarsToWrite;

  function checkVars() public view {
    console.log("Checking that required environment variables are set");
    string[] memory envVars = _getEnvVars();
    string memory errorString;
    for (uint256 i; i < envVars.length; ++i) {
      string memory envVar = string.concat(s_env, "_", envVars[i]);
      if (!_checkVar(envVar)) {
        errorString = string.concat(errorString, string.concat(envVar, " is not set\n"));
      }
    }

    if (bytes(errorString).length != 0) {
      revert(errorString);
    }
  }

  function setVars() public {
    console.log("Setting env vars");
    string[] memory vars = _getEnvVars();
    for (uint256 i; i < vars.length; ++i) {
      string memory envVar = string.concat(s_env, "_", vars[i]);
      vm.setEnv(vars[i], vm.envString(envVar));
    }
  }

  function setVmEnvVar(string memory name, address value) public {
    vm.setEnv(name, vm.toString(value));
  }

  function addEnvVarToWrite(
    string memory varName
  ) public {
    s_envVarsToWrite.push(varName);
  }

  function writeNextJSVars() public {
    console.log("Writing environment variables for nextjs");
    vm.writeLine(".envrc", "\n");
    for (uint256 i; i < s_envVarsToWrite.length; ++i) {
      string memory envVar = s_envVarsToWrite[i];
      vm.writeLine(
        ".envrc",
        string.concat(
          "export NEXT_PUBLIC_CL_PICASSO_", envVar, "_", s_env, "=", vm.envString(envVar)
        )
      );
    }
  }

  function _setEnv(
    string memory env
  ) internal virtual {
    s_env = env;
  }

  function _checkVar(
    string memory envVar
  ) private view returns (bool) {
    return bytes(vm.envOr(envVar, string(""))).length != 0;
  }

  function _getEnvVars() private view returns (string[] memory) {
    return s_requiredEnvVars;
  }
}
