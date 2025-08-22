// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import { BaseTest } from "./BaseTest.sol";
import { MINIMUM_VIABLE_CONTRACT_CREATION_CODE } from "../src/Constants.sol";

contract BaseCreate2ScriptTest is BaseTest {
    function testImmutableCreate2() public {
        address mvi = test.immutableCreate2IfNotDeployed(bytes32(0), MINIMUM_VIABLE_CONTRACT_CREATION_CODE);
        assertEq(mvi, 0xCb2c6Aa22d94247Efe9E34D0d90729A1c7aF7A9e);
    }

    function testCreate2AlreadyDeployed() public {
        bytes32 salt = bytes32(0);
        bytes memory initCode = MINIMUM_VIABLE_CONTRACT_CREATION_CODE;
        address result = test.create2IfNotDeployed(salt, initCode);
        address result2 = test.create2IfNotDeployed(salt, initCode);
        assertEq(result, result2);
    }

    function testImmutableCreate2AlreadyDeployed() public {
        bytes32 salt = bytes32(0);
        bytes memory initCode = MINIMUM_VIABLE_CONTRACT_CREATION_CODE;
        address result = test.immutableCreate2IfNotDeployed(salt, initCode);
        address result2 = test.immutableCreate2IfNotDeployed(salt, initCode);
        assertEq(result, result2);
    }

    function testDoubleEtch() public {
        bytes32 salt = bytes32(0);
        bytes memory initCode = MINIMUM_VIABLE_CONTRACT_CREATION_CODE;
        address result = test.create2IfNotDeployed(salt, initCode);
        salt = bytes32(uint256(1));
        address result2 = test.immutableCreate2IfNotDeployed(salt, initCode);
        assertFalse(result == result2);
    }

    function testCreate3AlreadyDeployed() public {
        bytes32 salt = bytes32(0);
        bytes memory creationCode = MINIMUM_VIABLE_CONTRACT_CREATION_CODE;
        address result = test.create3IfNotDeployed(salt, creationCode);
        address result2 = test.create3IfNotDeployed(salt, creationCode);
        assertEq(result, result2);
    }
}
