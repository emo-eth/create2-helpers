// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import { Script, console2 } from "forge-std/Script.sol";
import { IImmutableCreate2Factory } from "../src/IImmutableCreate2Factory.sol";
import { ICreate3Factory } from "../src/ICreate3Factory.sol";
import { ICreateX } from "../src/ICreateX.sol";
import { IDeterministicProxyFactory } from "./IDeterministicProxyFactory.sol";
import {
    IMMUTABLE_CREATE2_ADDRESS,
    IMMUTABLE_CREATE2_RUNTIME_BYTECODE,
    CREATEX_FACTORY,
    CREATEX_RUNTIME_BYTECODE,
    CREATE3_FACTORY,
    CREATE3_RUNTIME_BYTECODE,
    DETERMINISTIC_PROXY_FACTORY,
    DETERMINISTIC_PROXY_FACTORY_RUNTIME_BYTECODE,
    MINIMAL_UUPS,
    MINIMAL_UUPS_RUNTIME_BYTECODE
} from "../src/Constants.sol";

contract BaseCreate2Script is Script {
    uint256 constant FALLBACK_PRIVATE_KEY = 1;
    // forge-lint: disable-next-line(unsafe-typecast)
    address constant FALLBACK_DEPLOYER = address(bytes20("fallback"));
    // don't send any real money etc here :)
    uint256 constant FIRST_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    // to be set when running
    address deployer;

    constructor() {
        setUp();
    }

    function setUp() public virtual {
        // legacy - try to load private key from env var
        uint256 pkey = vm.envOr("DEPLOYER_PRIVATE_KEY", FALLBACK_PRIVATE_KEY);
        // try to load deployer from env var
        deployer = vm.envOr("DEPLOYER", FALLBACK_DEPLOYER);
        // if a private key is set, use it, and log a warning
        if (pkey != FALLBACK_PRIVATE_KEY) {
            console2.log(
                "DEPLOYER_PRIVATE_KEY env var is deprecated in favor of wallet keystores passed via --account; see `cast wallet` docs for more info"
            );
            deployer = vm.rememberKey(pkey);
        } else if (deployer == FALLBACK_DEPLOYER) {
            // if neither a private key nor a deployer is set, use a dummy private key
            console2.log("DEPLOYER env var not set; using dummy private key");
            deployer = vm.rememberKey(FIRST_ANVIL_PRIVATE_KEY);
        }
        // otherwise continue using the deployer from the env var
    }

    /**
     * @notice Given a list of networks, fork each network and execute the deployLogic function for each one.
     */
    function runOnNetworks(function() internal returns (address) runLogic, string[] memory networks) internal virtual {
        for (uint256 i = 0; i < networks.length; i++) {
            string memory network = networks[i];
            vm.createSelectFork(vm.rpcUrl(network));
            console2.log("Running on network: ", network);
            runLogic();
        }
    }

    /**
     * @notice Given a list of networks, fork each network and execute the deployLogic function for each one.
     */
    function runOnNetworks(function() internal runLogic, string[] memory networks) internal virtual {
        for (uint256 i = 0; i < networks.length; i++) {
            string memory network = networks[i];
            vm.createSelectFork(vm.rpcUrl(network));
            console2.log("Running on network: ", network);
            runLogic();
        }
    }

    /**
     * @dev Create2 a contract using the ImmutableCreate2Factory, with the specified initCode
     */
    function _immutableCreate2IfNotDeployed(bytes32 salt, bytes memory initCode) internal virtual returns (address) {
        return _immutableCreate2IfNotDeployed(msg.sender, salt, initCode);
    }

    /**
     * @dev Create2 a contract using the ImmutableCreate2Factory, with the specified initCode, broadcast by the specified broadcaster
     */
    function _immutableCreate2IfNotDeployed(address broadcaster, bytes32 salt, bytes memory initCode)
        internal
        virtual
        returns (address)
    {
        address expectedAddress = vm.computeCreate2Address(salt, keccak256(initCode), IMMUTABLE_CREATE2_ADDRESS);
        if (!immutableCreate2().hasBeenDeployed(expectedAddress)) {
            vm.broadcast(broadcaster);
            immutableCreate2().safeCreate2(salt, initCode);
        }
        return expectedAddress;
    }

    /**
     * @dev Create2 a contract using the Arachnid Create2 Factory, with the specified salt and initCode
     */
    function _create2IfNotDeployed(bytes32 salt, bytes memory initCode) internal virtual returns (address) {
        return _create2IfNotDeployed(msg.sender, 0, salt, initCode);
    }

    /**
     * @dev Create2 a contract using the Arachnid Create2 Factory, with the specified salt and initCode, broadcast by the
     *      specified broadcaster
     */
    function _create2IfNotDeployed(address broadcaster, bytes32 salt, bytes memory initCode)
        internal
        virtual
        returns (address)
    {
        return _create2IfNotDeployed(broadcaster, 0, salt, initCode);
    }

    /**
     * @dev Create2 a contract using the Arachnid Create2 Factory, with the specified salt and initCode, broadcast by the
     *      specified broadcaster with the specified value
     */
    function _create2IfNotDeployed(address broadcaster, uint256 value, bytes32 salt, bytes memory initCode)
        internal
        virtual
        returns (address)
    {
        address expectedAddress = vm.computeCreate2Address(salt, keccak256(initCode), CREATE2_FACTORY);
        if (expectedAddress.code.length == 0) {
            vm.broadcast(broadcaster);
            (bool success,) = CREATE2_FACTORY.call{ value: value }(bytes.concat(salt, initCode));
            require(success, "Create2 failed");
        }
        return expectedAddress;
    }

    /**
     * @dev Get the ImmutableCreate2Factory, etching the code if it is not deployed in a test or simulation
     */
    function immutableCreate2() internal virtual returns (IImmutableCreate2Factory) {
        // etch code at the address if we are simulating in a fork that does not have the factory deployed
        if (IMMUTABLE_CREATE2_ADDRESS.code.length == 0) {
            console2.log(
                "ImmutableCreate2Factory not found; etching code for simulation. \nSee "
                "https://github.com/ProjectOpenSea/seaport/blob/main/docs/Deployment.md#setting-up-factory-on-a-new-chain"
                " for instructions on how to deploy the ImmutableCreate2Factory to a new network."
            );
            vm.etch(IMMUTABLE_CREATE2_ADDRESS, IMMUTABLE_CREATE2_RUNTIME_BYTECODE);
            vm.label(IMMUTABLE_CREATE2_ADDRESS, "ImmutableCreate2Factory");
        }
        return IImmutableCreate2Factory(IMMUTABLE_CREATE2_ADDRESS);
    }

    /**
     * @dev Create3 a contract using the Create3Factory, with the specified salt and creationCode
     */
    function _create3IfNotDeployed(bytes32 salt, bytes memory creationCode) internal virtual returns (address) {
        return _create3IfNotDeployed(msg.sender, 0, salt, creationCode);
    }

    /**
     * @dev Create3 a contract using the Create3Factory, with the specified salt and creationCode,
     *      broadcast by the specified broadcaster
     */
    function _create3IfNotDeployed(address broadcaster, bytes32 salt, bytes memory creationCode)
        internal
        virtual
        returns (address)
    {
        return _create3IfNotDeployed(broadcaster, 0, salt, creationCode);
    }

    /**
     * @dev Create3 a contract using the Create3Factory, with the specified salt and creationCode,
     *      broadcast by the specified broadcaster with the specified value
     */
    function _create3IfNotDeployed(address broadcaster, uint256 value, bytes32 salt, bytes memory creationCode)
        internal
        virtual
        returns (address)
    {
        address expectedAddress = create3().getDeployed(broadcaster, salt);
        if (expectedAddress.code.length == 0) {
            vm.broadcast(broadcaster);
            address deployed = create3().deploy{ value: value }(salt, creationCode);
            require(deployed == expectedAddress, "Create3 address mismatch");
        }
        return expectedAddress;
    }

    /**
     * @dev Get the Create3Factory, etching the code if it is not deployed in a test or simulation
     */
    function create3() internal virtual returns (ICreate3Factory) {
        if (CREATE3_FACTORY.code.length == 0) {
            console2.log("Create3Factory not found; etching code for simulation.");
            vm.etch(CREATE3_FACTORY, CREATE3_RUNTIME_BYTECODE);
            vm.label(CREATE3_FACTORY, "CREATE3Factory");
        }
        return ICreate3Factory(CREATE3_FACTORY);
    }

    /**
     * @dev CreateX (CREATE3): deploy with the specified uint88 salt and creationCode.
     *      The effective salt is guarded by the broadcaster to produce a consistent per-broadcaster address.
     */
    function _createX3IfNotDeployed(uint88 salt, bytes memory creationCode) internal virtual returns (address) {
        return _createX3IfNotDeployed(msg.sender, 0, salt, creationCode);
    }

    /**
     * @dev CreateX (CREATE3): deploy with the specified uint88 salt and creationCode,
     *      broadcast by the specified broadcaster.
     */
    function _createX3IfNotDeployed(address broadcaster, uint88 salt, bytes memory creationCode)
        internal
        virtual
        returns (address)
    {
        return _createX3IfNotDeployed(broadcaster, 0, salt, creationCode);
    }

    /**
     * @dev CreateX (CREATE3): deploy with the specified uint88 salt and creationCode,
     *      broadcast by the specified broadcaster and forwarding the specified value.
     */
    function _createX3IfNotDeployed(address broadcaster, uint256 value, uint88 salt, bytes memory creationCode)
        internal
        virtual
        returns (address)
    {
        bytes32 intermediateSalt = bytes32(uint256(uint160(broadcaster)) << 96 | uint256(salt));
        bytes32 guardedSalt;
        assembly {
            mstore(0x00, broadcaster)
            mstore(0x20, intermediateSalt)
            guardedSalt := keccak256(0x00, 0x40)
        }
        address expectedAddress = createX().computeCreate3Address(guardedSalt);
        if (expectedAddress.code.length == 0) {
            ICreateX _createX = createX();
            vm.broadcast(broadcaster);
            address deployed = _createX.deployCreate3{ value: value }(intermediateSalt, creationCode);
            require(deployed == expectedAddress, "CreateX create3 address mismatch");
        }
        return expectedAddress;
    }

    /**
     * @dev Get the CreateX factory, etching the code if it is not deployed in a test or simulation
     */
    function createX() internal virtual returns (ICreateX) {
        if (CREATEX_FACTORY.code.length == 0) {
            console2.log("CreateXFactory not found; etching code for simulation.");
            vm.etch(CREATEX_FACTORY, CREATEX_RUNTIME_BYTECODE);
            vm.label(CREATEX_FACTORY, "CreateX");
        }
        return ICreateX(CREATEX_FACTORY);
    }

    function _deployDeterministicProxyIfNotDeployed(
        address implementation,
        uint96 salt,
        bytes memory callData,
        bytes memory immutableArgs
    ) internal virtual returns (address) {
        return _deployDeterministicProxyIfNotDeployed(msg.sender, implementation, salt, callData, immutableArgs);
    }

    function _deployDeterministicProxyIfNotDeployed(
        address broadcaster,
        address implementation,
        uint96 salt,
        bytes memory callData,
        bytes memory immutableArgs
    ) internal virtual returns (address) {
        IDeterministicProxyFactory _deterministicProxyFactory = deterministicProxyFactory();
        bytes32 fullSalt = bytes32(uint256(uint160(broadcaster)) << 96 | uint256(salt));
        // Use the factory's own method to get the initcode hash, then compute CREATE2 address
        bytes32 initCodeHash = _deterministicProxyFactory.getInitcodeHashForProxy(implementation, immutableArgs);
        // The factory uses CREATE2 internally, so the deployer is the factory address, not the broadcaster
        address predictedAddress = predictDeterministicAddress(initCodeHash, fullSalt, DETERMINISTIC_PROXY_FACTORY);
        if (predictedAddress.code.length == 0) {
            vm.broadcast(broadcaster);
            address deployed = _deterministicProxyFactory.deploy(implementation, fullSalt, callData, immutableArgs);
            require(deployed == predictedAddress, "DeterministicProxyFactory deploy address mismatch");
        }
        return predictedAddress;
    }

    function deterministicProxyFactory() internal virtual returns (IDeterministicProxyFactory) {
        if (DETERMINISTIC_PROXY_FACTORY.code.length == 0) {
            console2.log("DeterministicProxyFactory not found; etching code for simulation.");
            vm.etch(DETERMINISTIC_PROXY_FACTORY, DETERMINISTIC_PROXY_FACTORY_RUNTIME_BYTECODE);
            vm.label(DETERMINISTIC_PROXY_FACTORY, "DeterministicProxyFactory");
        }
        if (MINIMAL_UUPS.code.length == 0) {
            console2.log("MinimalUups not found; etching code for simulation.");
            vm.etch(MINIMAL_UUPS, MINIMAL_UUPS_RUNTIME_BYTECODE);
            vm.label(MINIMAL_UUPS, "MinimalUups");
        }
        return IDeterministicProxyFactory(DETERMINISTIC_PROXY_FACTORY);
    }

    /* Copied from Solady */

    /// @dev Returns the address when a contract with initialization code hash,
    /// `hash`, is deployed with `salt`, by `factoryAddress`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress(bytes32 hash, bytes32 salt, address factoryAddress)
        internal
        pure
        returns (address predicted)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, factoryAddress))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            mstore(0x35, 0) // Restore the overwritten part of the free memory pointer.
        }
    }
}
