// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import { BaseCreate2Script } from "script/BaseCreate2Script.s.sol";

contract PublicBaseCreate2 is BaseCreate2Script {
    function create2IfNotDeployed(bytes32 salt, bytes memory initCode) public payable returns (address) {
        return _create2IfNotDeployed(msg.sender, msg.value, salt, initCode);
    }

    function immutableCreate2IfNotDeployed(bytes32 salt, bytes memory initCode) public payable returns (address) {
        return _immutableCreate2IfNotDeployed(msg.sender, salt, initCode);
    }
}
