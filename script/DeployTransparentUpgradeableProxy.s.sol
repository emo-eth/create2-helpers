// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseCreate2Script, console2 } from "./BaseCreate2Script.s.sol";
import { TimelockController } from "openzeppelin-contracts/contracts/governance/TimelockController.sol";
import { TransparentUpgradeableProxy } from
    "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployTransparentUpgradeableProxy is BaseCreate2Script {
    function run() public {
        runOnNetworks(this.deploy, vm.envString("NETWORKS", ","));
    }

    function deploy() external returns (address) {
        return this.deployTransparentUpgradeableProxy(
            vm.envBytes32("TRANSPARENT_PROXY_SALT"),
            vm.envAddress("TRANSPARENT_PROXY_INITIAL_ADMIN"),
            vm.envAddress("TRANSPARENT_PROXY_INITIAL_IMPLEMENTATION"),
            vm.envBytes("TRANSPARENT_PROXY_INITIALIZATION_DATA")
        );
    }

    function deployTransparentUpgradeableProxy(
        bytes32 salt,
        address initialAdmin,
        address initialImplementation,
        bytes memory initializationData
    ) external returns (address) {
        bytes memory proxyInitCode = abi.encodePacked(
            type(TransparentUpgradeableProxy).creationCode,
            abi.encode(initialImplementation, initialAdmin, initializationData)
        );
        address transparentUpgradeableProxy = _immutableCreate2IfNotDeployed(deployer, salt, proxyInitCode);
        console2.log("TransparentUpgradeableProxy deployed at", address(transparentUpgradeableProxy));
        return transparentUpgradeableProxy;
    }
}
