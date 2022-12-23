// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev ImmutableSalt is a wrapper around a bytes32 that contains an address and a bytes12, with the address packed into
 * the first 20 bytes. The ImmutableCreate2Factory uses the address to determine if a msg.sender is allowed to deploy
 * a contract with a given salt. Specifying the null address as the deployer allows anyone to deploy a contract with
 * the given salt.
 */
type ImmutableSalt is bytes32;

uint256 constant DEPLOYER_SHIFT = 96;
uint96 constant BYTES12_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFF;

/**
 * @notice Creates an ImmutableSalt from an address and a bytes12.
 */
function createImmutableSalt(address _deployer, uint96 _salt) pure returns (ImmutableSalt immutableSalt) {
    ///@solidity memory-safe-assembly
    assembly {
        immutableSalt := or(_salt, shl(DEPLOYER_SHIFT, _deployer))
    }
}

/**
 * @notice Unwraps the deployer address from an ImmutableSalt.
 */
function deployer(ImmutableSalt immutableSalt) pure returns (address _deployer) {
    ///@solidity memory-safe-assembly
    assembly {
        _deployer := shr(DEPLOYER_SHIFT, immutableSalt)
    }
}

/**
 * @notice Unwraps the bytes12 salt from an ImmutableSalt as a bytes32 to avoid redundant masking by Solidity
 */
function salt(ImmutableSalt immutableSalt) pure returns (bytes32 _salt) {
    ///@solidity memory-safe-assembly
    assembly {
        _salt := and(immutableSalt, BYTES12_MASK)
    }
}

/**
 * @notice Creates an ImmutableSalt but returns it as a bytes32 so it's easier to work with.
 */
function createBytes32ImmutableSalt(address _deployer, uint96 _salt) pure returns (bytes32) {
    return ImmutableSalt.unwrap(createImmutableSalt(_deployer, _salt));
}

using { deployer, salt } for ImmutableSalt global;
