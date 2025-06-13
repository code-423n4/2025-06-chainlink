// SPDX-License-Identifier: MIT
/* solhint-disable no-console */
pragma solidity 0.8.26;

import {console} from "forge-std/console.sol";
import {BaseScript} from "../BaseScript.s.sol";
import {IBUILDFactory} from "../../src/interfaces/IBUILDFactory.sol";

contract SetSeasonUnlockStartTime is BaseScript {
  function run() public virtual usingBroadcast(vm.envUint("PRIVATE_KEY")) {
    string memory seasonConfigs = _loadConfigRawString("/scripts/configs/seasons.json");
    uint256 numSeasons = _getJsonArrayLength(seasonConfigs);
    for (uint256 i; i < numSeasons; ++i) {
      console.log("Configuring a season in BUILDFactory %s", i);
      string memory path = _getArrayIndexedItemPath(s_envJsonPath, i);
      IBUILDFactory.SeasonConfig memory config = IBUILDFactory.SeasonConfig({
        unlockStartsAt: uint40(
          vm.parseJsonUint(seasonConfigs, string.concat(path, "unlock_starts_at"))
        )
      });
      s_factory.setSeasonUnlockStartTime({
        seasonId: vm.parseJsonUint(seasonConfigs, string.concat(path, "id")),
        config: config
      });
    }
  }
}
