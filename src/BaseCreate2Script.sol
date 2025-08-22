// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import { Script, console2, StdChains } from "forge-std/Script.sol";
import { IImmutableCreate2Factory } from "../src/IImmutableCreate2Factory.sol";
import { ICreate3Factory } from "../src/ICreate3Factory.sol";
import {
    IMMUTABLE_CREATE2_ADDRESS,
    IMMUTABLE_CREATE2_RUNTIME_BYTECODE,
    CREATE3_FACTORY,
    CREATE3_RUNTIME_BYTECODE
} from "../src/Constants.sol";

contract BaseCreate2Script is Script {
    uint256 constant FALLBACK_PRIVATE_KEY = 1;
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
        }
        return ICreate3Factory(CREATE3_FACTORY);
    }
}
