// forge script scripts/scenarios/Scenario_SetupSepolia.s.sol:Scenario_SetupSepolia
// --broadcast -vvvv --rpc-url $SEPOLIA_RPC_URL

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {DeployERC20Token} from "../erc20/DeployERC20Token.s.sol";
import {DeployBUILDFactory} from "../build-factory/DeployBUILDFactory.s.sol";
import {AddProjects} from "../build-factory/AddProjects.s.sol";
import {DeployBUILDClaim} from "../build-claim/DeployBUILDClaim.s.sol";
import {Deposit} from "../build-claim/Deposit.s.sol";
import {SetSeasonUnlockStartTime} from "../build-factory/SetSeasonUnlockStartTime.s.sol";
import {SetProjectSeasonConfig} from "../build-factory/SetProjectSeasonConfig.s.sol";

contract Scenario_SetupSepolia is
  DeployERC20Token,
  DeployBUILDFactory,
  AddProjects,
  DeployBUILDClaim,
  Deposit,
  SetSeasonUnlockStartTime,
  SetProjectSeasonConfig
{
  string private constant ENV = "SEPOLIA";

  constructor() {
    _setEnv(ENV);
    checkVars();
    setVars();
  }

  function run()
    public
    virtual
    override(
      DeployERC20Token,
      DeployBUILDFactory,
      AddProjects,
      DeployBUILDClaim,
      Deposit,
      SetSeasonUnlockStartTime,
      SetProjectSeasonConfig
    )
  {
    DeployERC20Token.run();
    DeployBUILDFactory.run();
    AddProjects.run();
    DeployBUILDClaim.run();
    writeNextJSVars();

    Deposit.run();
    SetSeasonUnlockStartTime.run();
    SetProjectSeasonConfig.run();
  }
}
