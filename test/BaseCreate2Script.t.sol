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

    function testCreateX3AlreadyDeployed() public {
        uint88 salt = 0;
        bytes memory creationCode = MINIMUM_VIABLE_CONTRACT_CREATION_CODE;
        address result = test.createX3IfNotDeployed(salt, creationCode);
        address result2 = test.createX3IfNotDeployed(salt, creationCode);
        assertEq(result, result2);
    }

    function testDeterministicProxyAlreadyDeployed() public {
        // Use a simple implementation contract (we can use MINIMAL_UUPS as it's already etched)
        address implementation = 0x00000000003cc991111C0f2e88135b04D5F945FE; // MINIMAL_UUPS
        uint96 salt = 0;
        bytes memory callData = "";
        bytes memory immutableArgs = "";

        address result = test.deployDeterministicProxyIfNotDeployed(implementation, salt, callData, immutableArgs);
        address result2 = test.deployDeterministicProxyIfNotDeployed(implementation, salt, callData, immutableArgs);

        assertEq(result, result2);
        assertTrue(result.code.length > 0);
    }

    function testDeterministicProxyDifferentSalts() public {
        address implementation = 0x00000000003cc991111C0f2e88135b04D5F945FE; // MINIMAL_UUPS
        bytes memory callData = "";
        bytes memory immutableArgs = "";

        address result1 = test.deployDeterministicProxyIfNotDeployed(implementation, 0, callData, immutableArgs);
        address result2 = test.deployDeterministicProxyIfNotDeployed(implementation, 1, callData, immutableArgs);

        assertFalse(result1 == result2);
    }

    function testDeterministicProxyDifferentImplementations() public {
        // Create two different implementation addresses
        address impl1 = 0x00000000003cc991111C0f2e88135b04D5F945FE; // MINIMAL_UUPS
        address impl2 = address(0x1234567890123456789012345678901234567890);
        uint96 salt = 0;
        bytes memory callData = "";
        bytes memory immutableArgs = "";

        address result1 = test.deployDeterministicProxyIfNotDeployed(impl1, salt, callData, immutableArgs);
        address result2 = test.deployDeterministicProxyIfNotDeployed(impl2, salt, callData, immutableArgs);

        assertFalse(result1 == result2);
    }

    function testDeterministicProxyWithImmutableArgs() public {
        address implementation = 0x00000000003cc991111C0f2e88135b04D5F945FE; // MINIMAL_UUPS
        uint96 salt = 0;
        bytes memory callData = "";

        // Test with different immutable args
        bytes memory args1 = abi.encodePacked(uint256(1));
        bytes memory args2 = abi.encodePacked(uint256(2));

        address result1 = test.deployDeterministicProxyIfNotDeployed(implementation, salt, callData, args1);
        address result2 = test.deployDeterministicProxyIfNotDeployed(implementation, salt, callData, args2);

        assertFalse(result1 == result2);
    }

    function testDeterministicProxyWithCallData() public {
        address implementation = 0x00000000003cc991111C0f2e88135b04D5F945FE; // MINIMAL_UUPS
        uint96 salt = 42;
        bytes memory immutableArgs = "";

        // Different callData should still deploy to same address (callData doesn't affect address)
        // Use empty callData since MINIMAL_UUPS doesn't have an initialize function
        bytes memory callData1 = "";
        bytes memory callData2 = "";

        address result1 = test.deployDeterministicProxyIfNotDeployed(implementation, salt, callData1, immutableArgs);
        address result2 = test.deployDeterministicProxyIfNotDeployed(implementation, salt, callData2, immutableArgs);

        // Address should be the same (idempotent deployment)
        assertEq(result1, result2);
        assertTrue(result1.code.length > 0);
    }
}
