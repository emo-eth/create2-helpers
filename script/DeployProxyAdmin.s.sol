// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {BaseCreate2Script, console2} from "./BaseCreate2Script.s.sol";
import {ProxyAdmin} from "src/helpers/ProxyAdmin.sol";

contract DeployProxyAdmin is BaseCreate2Script {
    function run() public {
        setUp();
        runOnNetworks(deploy, vm.envString("NETWORKS", ","));
    }

    function deploy() public returns (address) {
        return deployProxyAdmin(vm.envAddress("INITIAL_PROXY_ADMIN_OWNER"));
    }

    function deployProxyAdmin(address initialAdmin) internal returns (address) {
        bytes memory initCode = abi.encodePacked(type(ProxyAdmin).creationCode, abi.encode(initialAdmin));
        address proxyAdmin = _immutableCreate2IfNotDeployed(deployer, bytes32(0), initCode);
        console2.log("ProxyAdmin deployed at", address(proxyAdmin));
        return proxyAdmin;
    }
}