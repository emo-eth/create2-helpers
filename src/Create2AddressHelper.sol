// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

library Create2AddressHelper {
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
