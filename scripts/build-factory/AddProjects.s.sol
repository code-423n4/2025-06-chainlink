// SPDX-License-Identifier: MIT
/* solhint-disable no-console */
pragma solidity 0.8.26;

import {console} from "forge-std/console.sol";
import {BaseScript} from "../BaseScript.s.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";
import {BUILDFactory} from "../../src/BUILDFactory.sol";

contract AddProjects is BaseScript {
  function run() public virtual usingBroadcast(vm.envUint("PRIVATE_KEY")) {
    console.log("Adding Projects to BUILDFactory");
    uint256 numProjects = s_tokens.length;
    BUILDFactory.AddProjectParams[] memory projects =
      new BUILDFactory.AddProjectParams[](numProjects);
    for (uint256 i; i < numProjects; ++i) {
      address token = address(s_tokens[i]);
      projects[i] =
        IBUILDFactory.AddProjectParams({token: token, admin: vm.envAddress("ADMIN_ADDRESS")});
    }
    s_factory.addProjects(projects);
  }
}
