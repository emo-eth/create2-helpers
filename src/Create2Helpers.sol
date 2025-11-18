// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

library Create2Helpers {
    address constant CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    /**
     * Compute the address of a contract deployed using CREATE2 using Nick's keyless create2 factory.
     * @param salt The salt to use for the CREATE2 operation.
     * @param initCode The initialization code to use for the CREATE2 operation.
     * @return result The address of the deployed contract.
     */
    function create2(bytes32 salt, bytes memory initCode) internal returns (address result) {
        (bool success,) = CREATE2_FACTORY.call(abi.encodePacked(salt, initCode));
        require(success, "CREATE2 failed");
        assembly {
            returndatacopy(0x0c, 0x00, 0x14)
            result := mload(0x00)
        }
        require(result == computeCreate2Address(CREATE2_FACTORY, salt, keccak256(initCode)), "CREATE2 address mismatch");
        return result;
    }

    function computeCreate2Address(address deployer, bytes32 salt, bytes memory initCode)
        internal
        pure
        returns (address)
    {
        return computeCreate2Address(deployer, salt, keccak256(initCode));
    }

    function computeCreate2Address(address deployer, bytes32 salt, bytes32 initCodeHash)
        internal
        pure
        returns (address)
    {
        return address(
            uint160( // downcast to match the address type.
                uint256( // convert to uint to truncate upper digits.
                    keccak256( // compute the CREATE2 hash using 4 inputs.
                        abi.encodePacked( // pack all inputs to the hash together.
                            bytes1(0xff), // start with 0xff to distinguish from RLP.
                            deployer, // this contract will be the caller.
                            salt, // pass in the supplied salt value.
                            initCodeHash // pass in the hash of initialization code.
                        )
                    )
                )
            )
        );
    }
}
