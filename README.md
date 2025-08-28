# create2-helpers

create2-helpers is a suite of smart contracts and forge scripts meant to make working with cross-chain deterministic deployments easier and more convenient.

It leverages Forge's default [Arachnid Deterministic Deployment Proxy](https://github.com/Arachnid/deterministic-deployment-proxy) as well as 0age's [ImmutableCreate2Factory](https://github.com/0age/metamorphic/blob/master/contracts/ImmutableCreate2Factory.sol).

## Usage Guide

### Installation

To install create2-helpers in your Foundry project:

```bash
forge soldeer install create2-helpers~0.4.0
# or
forge install emo-eth/create2-helpers
```

### Key Components

1. **BaseCreate2Script**: A base script that provides utility functions for deterministic deployments across chains
2. **Create2AddressHelper**: Helper functions for computing CREATE2 addresses
3. **ImmutableSalt**: A wrapper around bytes32 that helps work with the ImmutableCreate2Factory
4. **Constants**: Predefined constants for CREATE2/CREATE3/CreateX factories and deployment code

### Creating a Deployment Script

Here's how to create a script for deterministic deployment across multiple chains:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import { BaseCreate2Script } from "create2-helpers/BaseCreate2Script.sol";
import { YourContract } from "../src/YourContract.sol";
// if using a non-default network, you can configure their RPC urls using StdChains::setChain
import { StdChains } from "forge-std/StdChains.sol";

contract DeployYourContract is BaseCreate2Script {
    function run() public {
        // if necessary, configure any chains not part of the standard networks included in forge-std
        // vm.rpcUrl will read from the [rpc_endpoints] section in foundry.toml
        setChain(
            "example", StdChains.ChainData({ name: "Example Chain", chainId: 12345, rpcUrl: vm.rpcUrl("example") })
        );
        // Run on networks specified in the NETWORKS environment variable
        // Format: "mainnet,optimism,arbitrum_one"
        runOnNetworks(this.deploy, vm.envString("NETWORKS", ","));
    }

    function deploy() public returns (address) {
        // Create initialization code with constructor parameters if needed
        bytes memory initCode = abi.encodePacked(type(YourContract).creationCode);

        // Use the same salt across all chains for deterministic address
        bytes32 salt = bytes32(uint256(0x123)); // Example salt

        // Deploy using ImmutableCreate2Factory if not already deployed
        address deployedAddress = _immutableCreate2IfNotDeployed(salt, initCode);

        // Deploy using Nick's Keyless CREATE2 Proxy if not already deployed
        address deployedAddress2 = _create2IfNotDeployed(salt, initCode);

        // if using multiple deployers, specify the deployer for the contract
        address deployedAddress3 = _create2IfNotDeployed(deployer, salt, initCode);
        address deployedAddress4 = _immutableCreate2IfNotDeployed(salt, initCode);

        console2.log("Deployed YourContract at:", deployedAddress);
        return deployedAddress;
    }
}
```

### Configuring Your Deployment

1. Create an `.env` file containing
    1. `NETWORKS`: Comma-separated list of networks to deploy to
    2. `DEPLOYER`: The address that will deploy the contracts (optional)
2. Add custom RPC endpoints to the `[rpc_endpoints]` section of your `foundry.toml` (see [foundry.toml](./foundry.toml))
3. Use `cast wallet` and the `--accounts` flag to provide the private key for the deployer specified in the `.env` file

Note: `DEPLOYER_PRIVATE_KEY` is deprecated in favor of wallet keystores passed via `--account`. You can still set `DEPLOYER` to an address; if neither is set, a dummy anvil key is used when simulating locally.

### Running Your Deployment

1. Create a `.env` file with your endpoints as specified in the `foundry.toml` file

```bash
source .env
forge script script/DeployYourContract.s.sol --sig "run()" -vvv --broadcast --verify --env-file .env
```

Or for specific networks:

```bash
NETWORKS="mainnet,optimism" forge script script/DeployYourContract.s.sol --sig "run()" -vvv --broadcast --verify --env-file .env
```

### Advanced Usage

#### Using ImmutableSalt

The `ImmutableSalt` type allows you to restrict which addresses can deploy a contract with a specific salt:

```solidity
import { ImmutableSalt, createBytes32ImmutableSalt } from "create2-helpers/src/ImmutableSalt.sol";

// Create a salt that only allows a specific address to deploy
bytes32 salt = createBytes32ImmutableSalt(specificDeployer, uint96(0x123));

// Create a salt that allows anyone to deploy
bytes32 salt = createBytes32ImmutableSalt(address(0), uint96(0x123));
```

#### Computing CREATE2 Addresses

```solidity
import { Create2AddressHelper } from "create2-helpers/src/Create2AddressHelper.sol";

// Compute the address before deployment
address expectedAddress = Create2AddressHelper.computeCreate2Address(
    factory,
    salt,
    initCode
);
```

#### Using CREATE3

`BaseCreate2Script` provides helpers for CREATE3 via a canonical factory:

```solidity
// Deploy with CREATE3 if not already deployed
bytes32 salt = bytes32(uint256(0x123));
bytes memory creationCode = abi.encodePacked(type(YourContract).creationCode);
address deployed = _create3IfNotDeployed(salt, creationCode);
```

#### Using CreateX (CREATE, CREATE2, CREATE3)

`BaseCreate2Script` also integrates with the CreateX factory. For CREATE3-style deployments, use the `_createX3IfNotDeployed` helpers. The salt is a compact `uint88` value; the final address is derived from a guarded salt that mixes the broadcaster address and the provided salt.

```solidity
// Deploy with CreateX (CREATE3) if not already deployed
uint88 salt88 = 0x123;
bytes memory creationCode = abi.encodePacked(type(YourContract).creationCode);
address deployed = _createX3IfNotDeployed(salt88, creationCode);

// You can also specify the broadcaster and value sent with the deployment
address broadcaster = deployer;
uint256 value = 0;
address deployed2 = _createX3IfNotDeployed(broadcaster, value, salt88, creationCode);
```

To pre-compute the expected address for CreateX CREATE3, `BaseCreate2Script` internally derives a guarded salt as `keccak256(abi.encode(broadcaster, bytes32(uint256(uint160(broadcaster)) << 96 | uint256(salt88))))` and queries `createX().computeCreate3Address(guardedSalt)`.
