// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

type ImmutableSalt is bytes32;

uint256 constant DEPLOYER_SHIFT = 96;

function constructImmutableSalt(address _deployer, bytes12 _salt) pure returns (ImmutableSalt immutableSalt) {
    ///@solidity memory-safe-assembly
    assembly {
        immutableSalt := or(_salt, shl(DEPLOYER_SHIFT, _deployer))
    }
}

function deployer(ImmutableSalt immutableSalt) pure returns (address _deployer) {
    ///@solidity memory-safe-assembly
    assembly {
        _deployer := shr(DEPLOYER_SHIFT, immutableSalt)
    }
}

function salt(ImmutableSalt immutableSalt) pure returns (uint96 _salt) {
    ///@solidity memory-safe-assembly
    assembly {
        _salt :=
            and(immutableSalt, 0x00000000000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
    }
}

using {deployer, salt} for ImmutableSalt global;
