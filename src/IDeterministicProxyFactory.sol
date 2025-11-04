// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IDeterministicProxyFactory {
    error InvalidDeployer();
    error ProxyCallFailed();

    function clone(address implementation, bytes32 salt, bytes memory callData, bytes memory immutableArgs)
        external
        payable
        returns (address);
    function deploy(address implementation, bytes32 salt, bytes memory callData, bytes memory immutableArgs)
        external
        payable
        returns (address);
    function deployBeaconProxy(address beacon, bytes32 salt, bytes memory callData, bytes memory immutableArgs)
        external
        payable
        returns (address);
    function getInitcodeHashForBeaconProxy(address _beacon, bytes memory immutableArgs) external pure returns (bytes32);
    function getInitcodeHashForClone(address implementation, bytes memory immutableArgs) external pure returns (bytes32);
    function getInitcodeHashForProxy(address _implementation, bytes memory immutableArgs)
        external
        pure
        returns (bytes32);
}
