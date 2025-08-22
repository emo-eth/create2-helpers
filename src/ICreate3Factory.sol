// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ICreate3Factory {
    function deploy(bytes32 salt, bytes memory creationCode) external payable returns (address deployed);
    function getDeployed(address deployer, bytes32 salt) external view returns (address deployed);
}
