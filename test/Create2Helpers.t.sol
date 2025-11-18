// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import { Test } from "forge-std/Test.sol";
import { Create2Helpers } from "../src/Create2Helpers.sol";
import { MINIMUM_VIABLE_CONTRACT_CREATION_CODE } from "../src/Constants.sol";

contract Create2HelpersTest is Test {
    function testCreate2() public {
        bytes32 salt = bytes32(uint256(1));
        bytes memory initCode = MINIMUM_VIABLE_CONTRACT_CREATION_CODE;

        address deployed = Create2Helpers.create2(salt, initCode);

        // Verify the deployed address matches the computed address
        address expected = Create2Helpers.computeCreate2Address(CREATE2_FACTORY, salt, initCode);
        assertEq(deployed, expected);

        // Verify code was deployed
        assertTrue(deployed.code.length > 0);
    }

    function testCreate2DifferentSalts() public {
        bytes memory initCode = MINIMUM_VIABLE_CONTRACT_CREATION_CODE;

        address deployed1 = Create2Helpers.create2(bytes32(uint256(10)), initCode);
        address deployed2 = Create2Helpers.create2(bytes32(uint256(20)), initCode);

        assertFalse(deployed1 == deployed2);
    }

    function testComputeCreate2AddressWithInitCode() public {
        bytes32 salt = bytes32(uint256(1));
        bytes memory initCode = MINIMUM_VIABLE_CONTRACT_CREATION_CODE;

        address computed = Create2Helpers.computeCreate2Address(CREATE2_FACTORY, salt, initCode);
        address computedWithHash = Create2Helpers.computeCreate2Address(CREATE2_FACTORY, salt, keccak256(initCode));

        assertEq(computed, computedWithHash);
    }

    function testComputeCreate2AddressWithHash() public {
        bytes32 salt = bytes32(uint256(1));
        bytes32 initCodeHash = keccak256(MINIMUM_VIABLE_CONTRACT_CREATION_CODE);

        address computed = Create2Helpers.computeCreate2Address(CREATE2_FACTORY, salt, initCodeHash);

        // Manually compute expected address
        address expected =
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), CREATE2_FACTORY, salt, initCodeHash)))));

        assertEq(computed, expected);
    }
}
