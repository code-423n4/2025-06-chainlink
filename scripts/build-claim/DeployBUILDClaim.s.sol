// SPDX-License-Identifier: MIT
/* solhint-disable no-console */
pragma solidity 0.8.26;

import {console} from "forge-std/console.sol";
import {BaseScript} from "../BaseScript.s.sol";
import {BUILDClaim} from "../../src/BUILDClaim.sol";

contract DeployBUILDClaim is BaseScript {
  function run() public virtual usingBroadcast(vm.envUint("PRIVATE_KEY")) {
    string memory varNamePrefix = "BUILD_CLAIM_";
    uint256 numProjects = s_tokens.length;
    for (uint256 i; i < numProjects; ++i) {
      console.log("Deploying BUILDClaim %s", i);
      address token = address(s_tokens[i]);
      BUILDClaim claim = s_factory.deployClaim(address(token));
      s_claims.push(claim);
      string memory varName = string.concat(varNamePrefix, vm.toString(i));
      setVmEnvVar(varName, address(claim));
      addEnvVarToWrite(varName);
    }
  }
}
