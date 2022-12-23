// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseTest } from "./BaseTest.sol";
import { SAFE_PROXY_FACTORY_1_3_0_CREATION_CODE, MINIMUM_VIABLE_CONTRACT_CREATION_CODE } from "../src/lib/Constants.sol";

contract BaseCreate2ScriptTest is BaseTest {
    address constant SAFE_PROXY_FACTORY_1_3_0_ADDRESS = 0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2;
    address constant MINIMUM_VIABLE_CONTRACT_ADDRESS = 0x5EB55A6805b5E0A6ACec8803a31aaaae4D6c275E;

    function testDeploySafeProxy() public {
        bytes32 salt = bytes32(0);
        bytes memory initCode = SAFE_PROXY_FACTORY_1_3_0_CREATION_CODE;
        address result = test.create2IfNotDeployed(salt, initCode);
        assertEq(result, SAFE_PROXY_FACTORY_1_3_0_ADDRESS);
    }

    function testDeployMVC() public {
        address mvi = test.create2PlaceholderImplementation();
        assertEq(mvi, 0x5EB55A6805b5E0A6ACec8803a31aaaae4D6c275E);
    }

    function testImmutableCreate2() public {
        address mvi = test.immutableCreate2IfNotDeployed(bytes32(0), MINIMUM_VIABLE_CONTRACT_CREATION_CODE);
        assertEq(mvi, 0x5EB55A6805b5E0A6ACec8803a31aaaae4D6c275E);
    }

    function testCreate2AlreadyDeployed() public {
        bytes32 salt = bytes32(0);
        bytes memory initCode = SAFE_PROXY_FACTORY_1_3_0_CREATION_CODE;
        address result = test.create2IfNotDeployed(salt, initCode);
        address result2 = test.create2IfNotDeployed(salt, initCode);
        assertEq(result, result2);
    }

    function testImmutableCreate2AlreadyDeployed() public {
        bytes32 salt = bytes32(0);
        bytes memory initCode = SAFE_PROXY_FACTORY_1_3_0_CREATION_CODE;
        address result = test.immutableCreate2IfNotDeployed(salt, initCode);
        address result2 = test.immutableCreate2IfNotDeployed(salt, initCode);
        assertEq(result, result2);
    }

    function testDoubleEtch() public {
        bytes32 salt = bytes32(0);
        bytes memory initCode = SAFE_PROXY_FACTORY_1_3_0_CREATION_CODE;
        address result = test.create2IfNotDeployed(salt, initCode);
        salt = bytes32(uint256(1));
        address result2 = test.immutableCreate2IfNotDeployed(salt, initCode);
        assertFalse(result == result2);
    }
}
