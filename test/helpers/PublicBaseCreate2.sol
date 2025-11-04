// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import { BaseCreate2Script } from "src/BaseCreate2Script.sol";

contract PublicBaseCreate2 is BaseCreate2Script {
    function create2IfNotDeployed(bytes32 salt, bytes memory initCode) public payable returns (address) {
        return _create2IfNotDeployed(msg.sender, msg.value, salt, initCode);
    }

    function immutableCreate2IfNotDeployed(bytes32 salt, bytes memory initCode) public payable returns (address) {
        return _immutableCreate2IfNotDeployed(msg.sender, salt, initCode);
    }

    function create3IfNotDeployed(bytes32 salt, bytes memory creationCode) public payable returns (address) {
        return _create3IfNotDeployed(msg.sender, msg.value, salt, creationCode);
    }

    function createX3IfNotDeployed(uint88 salt, bytes memory creationCode) public payable returns (address) {
        return _createX3IfNotDeployed(msg.sender, msg.value, salt, creationCode);
    }

    function deployDeterministicProxyIfNotDeployed(
        address implementation,
        uint96 salt,
        bytes memory callData,
        bytes memory immutableArgs
    ) public payable returns (address) {
        return _deployDeterministicProxyIfNotDeployed(msg.sender, implementation, salt, callData, immutableArgs);
    }
}
