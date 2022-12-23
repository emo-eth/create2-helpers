// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Script, console2, StdChains } from "forge-std/Script.sol";
import { IImmutableCreate2Factory } from "../src/lib/IImmutableCreate2Factory.sol";
import {
    IMMUTABLE_CREATE2_ADDRESS,
    IMMUTABLE_CREATE2_RUNTIME_BYTECODE,
    MINIMUM_VIABLE_CONTRACT_CREATION_CODE
} from "../src/lib/Constants.sol";
import { Create2AddressDeriver } from "../src/lib/Create2AddressDeriver.sol";

contract BaseCreate2Script is Script {
    // to be set when running
    address deployer;

    constructor() {
        setUp();
    }

    function setUp() public virtual {
        deployer = vm.rememberKey(vm.envUint("DEPLOYER_PRIVATE_KEY"));
    }

    /**
     * @notice Given a list of networks, fork each network and execute the deployLogic function for each one.
     */
    function runOnNetworks(function() external returns (address) runLogic, string[] memory networks) internal virtual {
        for (uint256 i = 0; i < networks.length; i++) {
            string memory network = networks[i];
            vm.createSelectFork(StdChains.getChain(network).rpcUrl);
            console2.log("Running on network: ", network);
            runLogic();
        }
    }

    /**
     * @dev Create a contract with a single STOP (00) opcode (stopcode), broadcasted by the specified broadcaster
     *      Useful for proxy contracts whose initial implementation must be a smart contract
     */
    function _create2MinimumViableContract(address broadcaster) internal returns (address) {
        return _immutableCreate2IfNotDeployed(broadcaster, bytes32(0), MINIMUM_VIABLE_CONTRACT_CREATION_CODE);
    }

    /**
     * @dev Create2 a contract using the ImmutableCreate2Factory, with the specified initCode
     */
    function _immutableCreate2IfNotDeployed(bytes32 salt, bytes memory initCode) internal returns (address) {
        return _immutableCreate2IfNotDeployed(msg.sender, salt, initCode);
    }

    /**
     * @dev Create2 a contract using the ImmutableCreate2Factory, with the specified initCode, broadcast by the specified broadcaster
     */
    function _immutableCreate2IfNotDeployed(address broadcaster, bytes32 salt, bytes memory initCode)
        internal
        returns (address)
    {
        address expectedAddress = Create2AddressDeriver.deriveCreate2Address(IMMUTABLE_CREATE2_ADDRESS, salt, initCode);
        if (!immutableCreate2().hasBeenDeployed(expectedAddress)) {
            vm.broadcast(broadcaster);
            immutableCreate2().safeCreate2(salt, initCode);
        }
        return expectedAddress;
    }

    /**
     * @dev Create2 a contract using the Arachnid Create2 Factory, with the specified salt and initCode
     */
    function _create2IfNotDeployed(bytes32 salt, bytes memory initCode) internal returns (address) {
        return _create2IfNotDeployed(msg.sender, 0, salt, initCode);
    }

    /**
     * @dev Create2 a contract using the Arachnid Create2 Factory, with the specified salt and initCode, broadcast by the
     *      specified broadcaster
     */
    function _create2IfNotDeployed(address broadcaster, bytes32 salt, bytes memory initCode)
        internal
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
        returns (address)
    {
        address expectedAddress = Create2AddressDeriver.deriveCreate2Address(CREATE2_FACTORY, salt, initCode);
        if (expectedAddress.code.length == 0) {
            vm.broadcast(broadcaster);
            (bool success,) = CREATE2_FACTORY.call{value: value}(bytes.concat(salt, initCode));
            require(success, "Create2 failed");
        }
        return expectedAddress;
    }

    /**
     * @dev Get the ImmutableCreate2Factory, etching the code if it is not deployed in a test or simulation
     */
    function immutableCreate2() internal returns (IImmutableCreate2Factory) {
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
}
