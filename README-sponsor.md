# Chainlink Rewards

## Design

[Chainlink Rewards Contracts Technical Design](./ChainlinkRewardsContractsTechnicalDesign.pdf)

## Contracts

### Run coverage

> Please run this from the root directory.

```
pnpm coverage
```

### Run gas snapshots

To update the gas snapshot, run:

```
pnpm gas
```

To check the gas costs against the current snapshot, run:

```
pnpm test:gas
```

### Scaffolding unit tests

First set up:

```
cargo install bulloak
```

> Learn the BTT format [here](https://github.com/alexfertel/bulloak?tab=readme-ov-file#spec).

1. Create a function-name.tree file for your test cases:

```
BUILDFactoryConstructorTest
├── when the admin is set to the zero address
│   └── it should revert
├── when foo
│   └── it should bar
└── when the admin is set to a nonZero address
    └── it should grant the admin role to the admin address
```

2. Run the following command to generate a test file from all tree files (if one doesn't already exist)

```
pnpm test:scaffold
OR
bulloak scaffold -w ./**/*.tree && forge fmt
```

3. Validate test files against the tree files for missing test cases by running

```
pnpm test:check
OR
bulloak check ./**/*.tree --fix && forge fmt
```

### Deploy and setup contracts on Ethereum Sepolia

You should set the following environment variables in .env file:

```
SEPOLIA_ADMIN_ADDRESS=
SEPOLIA_PRIVATE_KEY=
SEPOLIA_RPC_URL=
SEPOLIA_TOS_SIGNER=
```

You can also change the config files in the ./scripts/configs folder.

Run the following command:

```shell
$ forge script scripts/scenarios/Scenario_SetupSepolia.s.sol:Scenario_SetupSepolia --rpc-url <your_rpc_url> --broadcast -vvvv
```
