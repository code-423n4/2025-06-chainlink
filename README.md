# Chainlink Rewards audit details
- Total Prize Pool: $200,000 in USDC
  - HM awards: up to $185,000 in USDC
    - If no valid Highs or Mediums are found, the HM pool is $0
  - QA awards: $7,500 in USDC
  - Judge awards: $7,000 in USDC
  - Scout awards: $500 in USDC
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts June 16, 2025 20:00 UTC
- Ends July 16, 2025 20:00 UTC


### ❗️ Notes for auditors
1. **PoC required:** High- and Medium-risk submissions require a [coded, runnable Proof of Concept](https://docs.code4rena.com/competitions/submission-guidelines#required-proof-of-concept-poc-for-solidity-evm-audits). A dedicated ["Creating a PoC" section](#creating-a-poc) has been added to this `README` to aid in this regard.
1. **All submissions will be kept private:** The findings and report from this audit will remain private to the Chainlink team; the report will not be published publicly. [Wardens with the SR role](https://docs.code4rena.com/roles/sr-wardens) will be able to view submissions and participate in post-judging QA as usual, but all finding details, judge decisions, etc. will remain confidential. 
1. **Judging phase risk adjustments:**
    - High- or Medium-risk submissions downgraded to Low-risk (QA) will be ineligible for awards.
    - Upgrading a Low-risk finding from a QA report to a Medium- or High-risk finding is not supported.
    - As such, wardens are encouraged to select the appropriate risk level carefully during the submission phase.

## Automated findings / publicly known issues

The 4naly3er report can be found [here](https://github.com/code-423n4/2025-06-chainlink/blob/main/4naly3er-report.md).

_Note for C4 wardens: Anything included in this `Automated Findings / Publicly Known Issues` section is considered a publicly known issue and is ineligible for awards._

### Trust Assumptions

The `BUILDFactory` contract is configured with a zero-value `adminRoleTransferDelay`; this is a deliberate configuration and should be considered acceptable.

All roles assigned by the system are expected to be trustworthy and to invoke the relevant privileged functions of the system responsibly.

Malicious projects and non-standard token implementations are not expected to be in-scope as they will be vetted before being included in the system.

### Operational Assumptions

The system should permit a single `BUILDClaim` contract to be deployed for and attached to a token. Any redeployments / alternative tokens will have to deploy a new `BUILDClaim` contract per token.

Merkle proofs required for executing claim operations will be available to users through the Chainlink front-end after a user or their delegate goes through off-chain validations (i.e. Terms of Service acceptance / signing, wallet sanction / delegation checks, etc.).

Our server side validation is explicitly designed to gate access to the Merkle proofs.

The user that triggers a normal claim operation is not validated in any capacity and may trigger a normal claim on behalf of any other user. We consider this acceptable behaviour as well. 

### Design Document Correlation

The design documented listed as the documentation of the project includes additional optional functionality that may or may not be used at launch. Its documentation and code also contains parameter configuration values. 

These values are expected to be for illustration purposes only so as to explain how the code operates in an exemplary manner. The off-chain mechanism designs are subject to changes and the scope of the audit review **should focus on the on-chain smart contract logic**.

# Overview

[Chainlink Rewards (CLR)](https://blog.chain.link/chainlink-rewards-season-genesis) is a community engagement and rewards program designed to incentivize active participation in the Chainlink Network. The contracts in this document are designed to allow projects in the [Chainlink Build program](https://chain.link/economics/build-program) (CLR projects) to deploy an on-chain claim mechanism of their tokens for Chainlink ecosystem participants.

## Links

- **Documentation:** [Chainlink Rewards Contracts Technical Design](https://github.com/code-423n4/2025-06-chainlink/blob/main/docs/ChainlinkRewardsContractsTechnicalDesign.pdf)
- **Website:** [chain.link](https://chain.link/)
- **X/Twitter:** [@chainlink](https://twitter.com/chainlink)

---

# Scope

### Files in scope

| Contract   | SLoC | Purpose | Dependencies |
| - | - | - | - |
| [src/BUILDClaim.sol](https://github.com/code-423n4/2025-06-chainlink/blob/main/src/BUILDClaim.sol) | 262 | Facilitates vest claim operations for the Chainlink reward program | @openzeppelin/contracts/utils/introspection/IERC165.sol<br>@openzeppelin/contracts/token/ERC20/IERC20.sol<br>@openzeppelin/contracts/access/AccessControl.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>@openzeppelin/contracts/utils/Pausable.sol<br>@openzeppelin/contracts/utils/ReentrancyGuard.sol<br>@openzeppelin/contracts/utils/cryptography/MerkleProof.sol<br>@solmate/FixedPointMathLib.sol<br>chainlink/contracts/src/v0.8/shared/interfaces/ITypeAndVersion.sol |
| [src/BUILDFactory.sol](https://github.com/code-423n4/2025-06-chainlink/blob/main/src/BUILDFactory.sol) | 364 | Maintains `BUILDClaim` deployments for projects and their configuration as well as withdrawals | @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol<br>@openzeppelin/contracts/utils/structs/EnumerableSet.sol<br>@solmate/FixedPointMathLib.sol<br>@delegatexyz/delegate-registry/v2.0/src/IDelegateRegistry.sol<br>chainlink/contracts/src/v0.8/shared/interfaces/ITypeAndVersion.sol |
| **Total SLoC** | 626 | | |

*For a machine-readable version, see [scope.txt](https://github.com/code-423n4/2025-06-chainlink/blob/main/scope.txt)*

### Files out of scope

| File         |
| ------------ |
| [lib/\*\*.\*\*](https://github.com/code-423n4/2025-06-chainlink/tree/main/lib) |
| [scripts/\*\*.\*\*](https://github.com/code-423n4/2025-06-chainlink/tree/main/scripts) |
| [src/Closable.sol](https://github.com/code-423n4/2025-06-chainlink/blob/main/src/Closable.sol) |
| [src/ManagedAccessControl.sol](https://github.com/code-423n4/2025-06-chainlink/blob/main/src/ManagedAccessControl.sol) |
| [src/interfaces/\*\*.\*\*](https://github.com/code-423n4/2025-06-chainlink/tree/main/src/interfaces) |
| [src/mocks/\*\*.\*\*](https://github.com/code-423n4/2025-06-chainlink/tree/main/src/mocks) |
| [test/\*\*.\*\*](https://github.com/code-423n4/2025-06-chainlink/tree/main/test) |
| Totals: 76 |

*For a machine-readable version, see [out_of_scope.txt](https://github.com/code-423n4/2025-06-chainlink/blob/main/out_of_scope.txt)*

## Scoping Q&A

| Question | Answer |
| ---------------| ------------- |
| ERC20 used by the protocol | Canonical EIP-20 Tokens |
| ERC721 used by the protocol |	None |
| ERC777 used by the protocol |	None |
| ERC1155 used by the protocol | None |
| Chains the protocol will be deployed on	| Ethereum only |

### EIP compliance checklist 

#### EIP-20

The project tokens that are utilized and distributed by the `BUILDClaim` contract must be *canonical* EIP tokens that support the `decimals` metadata function.

In detail, fee-on-transfer tokens and balance-change-outside-of-transfer (i.e. rebasing etc.) tokens are not supported. 

Tokens may yield a `bool` to indicate successful execution of a transfer, may `revert` to indicate failure, and may not yield a `bool` at all.

Tokens should be able to execute normal EIP-20 transfers under all circumstances, and submissions that would concern this capability (i.e. blacklists, pausability, transfers of `0`, etc.) are not considered in-scope.

The system should be able to support tokens of varying decimal configurations as long as they are within sensible bounds (i.e. $0 \lt decimals \le 18$) and minuscule value truncations **in favour of the protocol / at the expense of the user** are considered acceptable.

#### EIP-165

The `BUILDClaim` contract is expected to comply with the EIP-165 interface support standard.

# Additional context

## Areas of concern (where to focus for bugs)

The team's largest concerns with the Chainlink Rewards S1 protocol are as follows.

### Functionality
 
- Integrity of the allocation and claim mechanisms (i.e. do allocations and claim operations conform to the specification of the design document)
- Can a project administrator successfully deploy their `BUILDClaim` contract after they have been included in the `BUILDFactory`? 
- Does a reward recipient earn the correct amount of rewards at all times?
- Are any non-negligible reward tokens locked into the contracts?
- Does multi-season claiming work as expected?
- Does early vesting penalization work correctly?
- Is early vesting authorization properly enforced (i.e. the user themselves or a delegate thereof should be able to execute this action)?
- Does delegation work correctly?

### Access Control

- Are all access control modifiers implemented correctly and enforced as expected?
- Are the role capabilities detailed within this document correctly restricted?
- If a project goes rogue, can the administrative capabilities in the system be utilized to minimize the project's impact to the system? Specifically, the capabilities we wish to have are:
  - Pause of a particular `BUILDToken` through the `BUILDClaim` contract
  - Cancellation of a project's withdrawal
  - Removal of a project from the `BUILDClaim` factory
  - Closure of the `BUILDClaim` factory
  - Replacement of a project administrator by the factory administrator
  - Scheduling of a withdrawal to a replaced project administrator address for recovery

## Main invariants

### Access Control

- After funding a `BUILDClaim` contract, Chainlink Reward projects should not be able to halt, exit, or do anything harmful to the system without the administrator's permission
- Only the Contract Administrator can update configurations, allowlist Chainlink Reward Project Administrators, start a refund, and schedule or cancel withdrawals
- Only Project Administrators can execute a scheduled withdrawal
 
### Project Management 

- Only allowlisted Project Administators can deploy `BUILDClaim` contracts. 
- `BUILDClaim` contracts can only be deployed and configured properly through the `BUILDFactory` contract

### Claiming and Vesting 

- Users can only claim unlocked tokens or, if enabled, early claim a portion of their unlocked tokens 
- Tokens vest according to the schedule (unlock duration, delay, etc.) 
- Chainlink Reward projects can withdraw only the allowed / available amount
- Token amount validation calculations do not result in mathematical overflows / underflows
 
### General 

- Contracts cannot be bricked (i.e. have a permanent or non-negligible Denial-of-Service imposed)
 
### Specific Invariants 

- More than the maximum token amount cannot be claimed 
- The claimable and refundable amount never exceeds the token balance of a project
- The `BUILDFactory` maximum available amount (`BUILDFactory::calcMaxAvailableAmount`) never exceeds the token balance of a project

#### Secondary Invariants

- The total refunded amount never exceeds the total allocated amount
- The total withdrawn amount never exceeds the total deposited amount
- The total withdrawn amount never exceeds the maximum possible withdrawn amount
- The total deposited and refunded amounts always equal or exceed the total allocated and withdrawn amounts if summed
- The total refunded amount never exceeds the total allocated amount for all seasons


## All trusted roles in the protocol

| Role                                | Description                    |
| ----------------------------------- | ------------------------------ |
| `BUILDFactory` Administrator (`DEFAULT_ADMIN_ROLE`)                       | - Manages project addition and removal to the factory<br>- Configures the maximum unlock duration and delay for project season configurations<br>- Configures a season's unlock start time<br>- Configures season configuration per project<br>- Starts a project's season refund<br>- Schedules a withdrawal<br>- Cancels a scheduled withdrawal<br>- Configures the delegate registry<br>- Can close the contract (i.e. render functions with the `Closable::whenOpen` modifier permanently inaccessible)           |
| Project Administrator (`s_projects[token].admin`)                    |                  - Can deploy a `BUILDClaim` contract through the `BUILDFactory` for their project's token<br>- Can deposit funds to their `BUILDClaim` contract<br>- Can execute scheduled withdrawals through their token's `BUILDClaim` contract |
| Pauser (`PAUSER_ROLE`)                             |       - Can pause and unpause capabilities of the `BUILDFactory` contract protected by the `Pausable::whenNotPaused` modifier<br>- Can pause or unpause a particular `BUILDClaim` contract          |
| Claimant (Part of `s_projectSeasonConfigs[token][seasonId].merkleRoot`)                          |           - Can claim registered rewards through the `BUILDClaim` contract<br>- Can execute an early vest to forfeit a portion of their rewards      |
| Claimant Delegate | - Can execute an early vest on behalf of the claimant they are delegated by |

## Describe any novel or unique curve logic or mathematical models implemented in the contracts:

Users are able to perform a one-time only "early vest" and receive a portion of their unvested tokens, forfeiting the remainder. The amount received from such an operation is proportional to the time remaining in a linear increasing band. 

Given the following configuration:

$$
minRatio: \text{the minimum Early Vest Ratio (EVR) at } t=0
$$
$$
maxRatio: \text{the maximum EVR at } t=T
$$

The EVR of a particular user would be:

$$
EVR(t) = minRatio +(maxRatio-minRatio)\times\frac{t}{T}
$$

This ratio can then be utilized alongside the allocation amount of the user and the bonus unvested token amount to assess the funds they would receive from their "early vest" operation:

$$
bonus\\_unvested\\_token\\_amount \*EVR(t)\*\frac{user\\_allocated\\_amount}{total\\_allocated\\_amount}
$$

## Running tests

The codebase utilizes the `forge` framework for compiling its contracts and executing tests coded in `Solidity`.

### Prerequisites

- `forge` (`1.1.0-dev` tested)
- `NodeJS` (`20.9.0` tested)
- `pnpm` (`10.12.1` tested) OR `npm` (`10.1.0` tested)
- Optional: 
    - `lcov` (`2.3.1` tested, `2.X` required) for HTML coverage report generation

### Setup

Once the above prerequisites have been successfully installed, the following commands can be executed to setup the repository:

```bash!
git clone https://github.com/code-423n4/2025-06-chainlink
cd 2025-06-chainlink
```

Depending on whether `pnpm` or `npm` is utilized, the respective command below should be executed:

```bash 
# pnpm v10.12.1
pnpm i

# npm v10.1.0
npm i 
```

After the relevant dependencies have been installed, the codebase is ready to be compiled and tested. The `package.json` file contains several handy commands that can be run to execute tests, perform coverage, and snapshot gas costs of the codebase.

### Tests

To run tests, the `test:solidity` command should be executed using your package manager of choice:

```bash  
# pnpm v10.12.1
pnpm test:solidity

# npm v10.1.0
npm run test:solidity
```

The tests may temporarily halt during its execution; this is normal and given adequate time, they are expected to finish successfully. 

On a Raspberry Pi 5 model B (`rev-1.1`), tests finished after `~53` minutes (`3200.91s`).

### Coverage

The `coverage` command can be executed to generate coverage reports that are converted into HTML and are automatically opened using your default browser:

```bash  
# pnpm v10.12.1
pnpm coverage

# npm v10.1.0
npm run coverage
```

Alternatively, if you do not have `lcov` installed, the following `foundry` command can be utilized to generate the `lcov.info` file manually:

```bash 
FOUNDRY_PROFILE=coverage forge coverage --report lcov
```

Afterward, the `lcov.info` file can be fed into any toolkit of your choice to generate the relevant report.

### Gas

The project supports gas snapshots as well as comparison. To create snapshots:

```bash 
# pnpm v10.12.1
pnpm gas

# npm v10.1.0
npm run gas
```

Snapshots can be utilized to compare differences in gas costs via the following command:

```bash
# pnpm v10.12.1
pnpm test:gas


# npm v10.1.0
npm run test:gas
```

## Creating a PoC

The Chainlink team has created a comprehensive setup `BaseTest` contract under [test/BaseTest.t.sol](https://github.com/code-423n4/2025-06-chainlink/blob/main/test/BaseTest.t.sol) that contains several verbose modifier implementations to aid in the creation of a PoC for one's submission. Additionally, the test suite exposes the project's contract deployments via storage variables (i.e. `s_claim` includes a basic `BUILDClaim` instance).

For example, to establish a claimable `BUILDClaim` instance the following modifiers should be applied:

```js 
// The season's configuration needs to be set
whenASeasonConfigIsSetForTheSeason
// A project must have been added and its `BUILDClaim` contract deployed
whenProjectAddedAndClaimDeployed
// Tokens must be available for claiming 
whenTokensAreDepositedForTheProject
// A season configuration should have been set for the `BUILDClaim` contract
whenASeasonConfigIsSetForTheProject
// We want a non-negligible amount to be claimable; we could use whenTheUnlockHasStartedForSeason1 here as well
whenTheUnlockIsInHalfWayForSeason1
```

Users are advised to take advantage of the modifiers within the `BaseTest` contract in the provided [test/PoC.t.sol](https://github.com/code-423n4/2025-06-chainlink/blob/main/test/PoC.t.sol) file to create the expected scenario setup to demonstrate a submission's vulnerability.

The PoC is included here for brevity:

```solidity
pragma solidity 0.8.26;

import {BaseTest} from "./BaseTest.t.sol";

contract PoC is BaseTest {
  function test_submissionValidity() 
    external
    // Modifiers of BaseTest for setup
  {
    // Proof of Concept code demonstrating the vulnerability
  }
}
```

The test case **should execute successfully** via the following command:

```bash 
forge test --match-test submissionValidity
```

## Miscellaneous

Employees of Chainlink and employees' family members are ineligible to participate in this audit.

Code4rena's rules cannot be overridden by the contents of this README. In case of doubt, please check with C4 staff.
