// SPDX-License-Identifier: MIT
/* solhint-disable no-console */
pragma solidity 0.8.26;

import {console} from "forge-std/console.sol";
import {BaseScript} from "../BaseScript.s.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

contract SetProjectSeasonConfig is BaseScript {
  function run() public virtual usingBroadcast(vm.envUint("PRIVATE_KEY")) {
    string memory projectSeasonConfigs =
      _loadConfigRawString("/scripts/configs/project_seasons.json");
    uint256 numProjectSeasons = _getJsonArrayLength(projectSeasonConfigs);
    for (uint256 i; i < numProjectSeasons; ++i) {
      console.log("Configuring a season in BUILDClaim %s", i);
      string memory path = _getArrayIndexedItemPath(s_envJsonPath, i);
      uint256 projectIndex =
        vm.parseJsonUint(projectSeasonConfigs, string.concat(path, "project_index"));
      IBUILDFactory.SetProjectSeasonParams[] memory params =
        new IBUILDFactory.SetProjectSeasonParams[](1);
      params[0] = IBUILDFactory.SetProjectSeasonParams({
        token: address(s_tokens[projectIndex]),
        seasonId: vm.parseJsonUint(projectSeasonConfigs, string.concat(path, "season_id")),
        tokenAmount: vm.parseJsonUint(projectSeasonConfigs, string.concat(path, "token_amount")),
        baseTokenClaimBps: uint16(
          vm.parseJsonUint(projectSeasonConfigs, string.concat(path, "base_token_claim_bps"))
        ),
        unlockDelay: uint40(
          vm.parseJsonUint(projectSeasonConfigs, string.concat(path, "unlock_delay"))
        ),
        unlockDuration: uint40(
          vm.parseJsonUint(projectSeasonConfigs, string.concat(path, "unlock_duration"))
        ),
        merkleRoot: vm.parseJsonBytes32(projectSeasonConfigs, string.concat(path, "merkle_root")),
        earlyVestRatioMinBps: vm.parseJsonBytes32(
          projectSeasonConfigs, string.concat(path, "earlyVestRatioMinBps")
        ),
        earlyVestRatioMaxBps: vm.parseJsonBytes32(
          projectSeasonConfigs, string.concat(path, "earlyVestRatioMaxBps")
        )
      });
      s_factory.setProjectSeasonConfig(params);
    }
  }
}
