

# Scope

*See [scope.txt](https://github.com/code-423n4/2025-06-chainlink/blob/main/scope.txt)*

### Files in scope


| File   | Logic Contracts | Interfaces | nSLOC | Purpose | Libraries used |
| ------ | --------------- | ---------- | ----- | -----   | ------------ |
| /src/BUILDClaim.sol | 1| **** | 262 | |chainlink/contracts/src/v0.8/shared/interfaces/ITypeAndVersion.sol<br>@openzeppelin/contracts/utils/introspection/IERC165.sol<br>@openzeppelin/contracts/token/ERC20/IERC20.sol<br>@openzeppelin/contracts/access/AccessControl.sol<br>@solmate/FixedPointMathLib.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>@openzeppelin/contracts/utils/Pausable.sol<br>@openzeppelin/contracts/utils/ReentrancyGuard.sol<br>@openzeppelin/contracts/utils/cryptography/MerkleProof.sol|
| /src/BUILDFactory.sol | 1| **** | 364 | |chainlink/contracts/src/v0.8/shared/interfaces/ITypeAndVersion.sol<br>@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol<br>@openzeppelin/contracts/utils/structs/EnumerableSet.sol<br>@solmate/FixedPointMathLib.sol<br>@delegatexyz/delegate-registry/v2.0/src/IDelegateRegistry.sol|
| **Totals** | **2** | **** | **626** | | |

### Files out of scope

*See [out_of_scope.txt](https://github.com/code-423n4/2025-06-chainlink/blob/main/out_of_scope.txt)*

| File         |
| ------------ |
| ./lib/vendor/chainlink/v2.18.0/contracts/src/v0.8/shared/access/ConfirmedOwner.sol |
| ./lib/vendor/chainlink/v2.18.0/contracts/src/v0.8/shared/access/ConfirmedOwnerWithProposal.sol |
| ./lib/vendor/chainlink/v2.18.0/contracts/src/v0.8/shared/interfaces/IAccessController.sol |
| ./lib/vendor/chainlink/v2.18.0/contracts/src/v0.8/shared/interfaces/IOwnable.sol |
| ./lib/vendor/chainlink/v2.18.0/contracts/src/v0.8/shared/interfaces/ITypeAndVersion.sol |
| ./lib/vendor/delegatexyz/delegate-registry/v2.0/src/DelegateRegistry.sol |
| ./lib/vendor/delegatexyz/delegate-registry/v2.0/src/IDelegateRegistry.sol |
| ./lib/vendor/delegatexyz/delegate-registry/v2.0/src/libraries/RegistryHashes.sol |
| ./lib/vendor/delegatexyz/delegate-registry/v2.0/src/libraries/RegistryOps.sol |
| ./lib/vendor/delegatexyz/delegate-registry/v2.0/src/libraries/RegistryStorage.sol |
| ./lib/vendor/space-and-time/SpaceAndTime.sol |
| ./scripts/BaseScript.s.sol |
| ./scripts/EnvManager.s.sol |
| ./scripts/build-claim/DeployBUILDClaim.s.sol |
| ./scripts/build-claim/Deposit.s.sol |
| ./scripts/build-claim/MsigMultiSendClaims.s.sol |
| ./scripts/build-factory/AddProjects.s.sol |
| ./scripts/build-factory/DeployBUILDFactory.s.sol |
| ./scripts/build-factory/SetProjectSeasonConfig.s.sol |
| ./scripts/build-factory/SetSeasonUnlockStartTime.s.sol |
| ./scripts/erc20/DeployERC20Token.s.sol |
| ./scripts/scenarios/Scenario_SetupSepolia.s.sol |
| ./src/Closable.sol |
| ./src/ManagedAccessControl.sol |
| ./src/interfaces/IBUILDClaim.sol |
| ./src/interfaces/IBUILDFactory.sol |
| ./src/mocks/ERC20Token.sol |
| ./src/mocks/FeeOnTransferERC20Token.sol |
| ./src/mocks/InvalidTransferERC20Token.sol |
| ./src/mocks/MultiSendCallOnly.sol |
| ./src/mocks/Multicall3.sol |
| ./src/mocks/MultisigWallet.sol |
| ./src/mocks/ReentrantERC20Token.sol |
| ./test/BUILDClaim/BuildClaim._getClaimableState.scenarios.t.sol |
| ./test/BUILDClaim/BuildClaim.claim.t.sol |
| ./test/BUILDClaim/BuildClaim.deposit.t.sol |
| ./test/BUILDClaim/BuildClaim.getGlobalState.t.sol |
| ./test/BUILDClaim/BuildClaim.getUserState.t.sol |
| ./test/BUILDClaim/BuildClaim.scenarios.t.sol |
| ./test/BUILDClaim/BuildClaim.withdraw.t.sol |
| ./test/BUILDFactory/BUILDFactory.AcceptDefaultAdminTransfer.t.sol |
| ./test/BUILDFactory/BUILDFactory.AddProjects.t.sol |
| ./test/BUILDFactory/BUILDFactory.AddTotalDeposited.t.sol |
| ./test/BUILDFactory/BUILDFactory.BeginDefaultAdminTransfer.t.sol |
| ./test/BUILDFactory/BUILDFactory.CalcMaxAvailableAmount.sol |
| ./test/BUILDFactory/BUILDFactory.CancelDefaultAdminTransfer.t.sol |
| ./test/BUILDFactory/BUILDFactory.CancelWithdraw.t.sol |
| ./test/BUILDFactory/BUILDFactory.Close.t.sol |
| ./test/BUILDFactory/BUILDFactory.DeployClaim.t.sol |
| ./test/BUILDFactory/BUILDFactory.EmergencyPause.t.sol |
| ./test/BUILDFactory/BUILDFactory.EmergencyUnpause.t.sol |
| ./test/BUILDFactory/BUILDFactory.ExecuteWithdraw.t.sol |
| ./test/BUILDFactory/BUILDFactory.GetRefundableAmount.t.sol |
| ./test/BUILDFactory/BUILDFactory.GetSeasonConfig.t.sol |
| ./test/BUILDFactory/BUILDFactory.GetTokenAmounts.t.sol |
| ./test/BUILDFactory/BUILDFactory.PauseClaimContract.t.sol |
| ./test/BUILDFactory/BUILDFactory.ReduceRefundableAmount.t.sol |
| ./test/BUILDFactory/BUILDFactory.RemoveProjects.t.sol |
| ./test/BUILDFactory/BUILDFactory.ScheduleWithdraw.t.sol |
| ./test/BUILDFactory/BUILDFactory.SetProjectSeasonConfig.t.sol |
| ./test/BUILDFactory/BUILDFactory.SetSeasonConfig.t.sol |
| ./test/BUILDFactory/BUILDFactory.SetUnlockConfigMaxValues.t.sol |
| ./test/BUILDFactory/BUILDFactory.StartRefund.t.sol |
| ./test/BUILDFactory/BUILDFactory.UnpauseClaimContract.t.sol |
| ./test/BUILDFactory/BUILDFactory.setDelegateRegistry.t.sol |
| ./test/BUILDFactory/BuildFactory.constructor.t.sol |
| ./test/BaseTest.t.sol |
| ./test/Constants.t.sol |
| ./test/ScenarioBuilder.t.sol |
| ./test/Utils.t.sol |
| ./test/gas/Gas_BUILDClaim.t.sol |
| ./test/gas/Gas_BUILDFactory.t.sol |
| ./test/invariants/BUILDClaim.invariants.t.sol |
| ./test/invariants/BUILDFactory.invariants.t.sol |
| ./test/invariants/BaseInvariant.t.sol |
| ./test/invariants/handlers/Handler.t.sol |
| Totals: 76 |

