// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseCreate2Script, console2 } from "./BaseCreate2Script.s.sol";
import { DeploySafe } from "./DeploySafe.s.sol";
import { DeployTimelockController } from "./DeployTimelockController.s.sol";
import { DeployProxyAdmin } from "./DeployProxyAdmin.s.sol";
import { DeployTransparentUpgradeableProxy } from "./DeployTransparentUpgradeableProxy.s.sol";

contract DeploySuite is BaseCreate2Script {
    function run() public {
        runOnNetworks(this.deploy, vm.envString("NETWORKS", ","));
    }

    function deploy() external returns (address) {
        address safe = (new DeploySafe()).deploy();
        vm.setEnv("TIMELOCK_PROPOSERS", vm.toString(safe));
        address timelock = (new DeployTimelockController()).deploy();
        vm.setEnv("INITIAL_PROXY_ADMIN_OWNER", vm.toString(timelock));
        address proxyAdmin = (new DeployProxyAdmin()).deploy();
        return (new DeployTransparentUpgradeableProxy()).deployTransparentUpgradeableProxy({
            salt: bytes32(uint256(1)),
            initialAdmin: proxyAdmin,
            initialImplementation: _create2MinimumViableContract(deployer),
            initializationData: ""
        });
    }
}
