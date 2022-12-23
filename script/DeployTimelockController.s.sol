// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseCreate2Script, console2 } from "./BaseCreate2Script.s.sol";
import { TimelockController } from "openzeppelin-contracts/contracts/governance/TimelockController.sol";

contract DeployTimelockController is BaseCreate2Script {
    struct TimelockConstructorParams {
        uint256 minimumDelay;
        address[] proposers;
        address[] executors;
        address admin;
    }

    function run() public {
        runOnNetworks(this.deploy, vm.envString("NETWORKS", ","));
    }

    function deploy() external returns (address) {
        return this.deployTimelock(
            TimelockConstructorParams({
                minimumDelay: vm.envUint("TIMELOCK_MINIMUM_DELAY_DAYS") * 1 days,
                proposers: vm.envAddress("TIMELOCK_PROPOSERS", ","),
                executors: vm.envAddress("TIMELOCK_EXECUTORS", ","),
                admin: vm.envAddress("TIMELOCK_ADMIN")
            })
        );
    }

    function deployTimelock(TimelockConstructorParams memory params) external returns (address) {
        bytes memory initCode = abi.encodePacked(
            type(TimelockController).creationCode,
            abi.encode(params.minimumDelay, params.proposers, params.executors, params.admin)
        );
        address timelock = _immutableCreate2IfNotDeployed(deployer, bytes32(0), initCode);
        console2.log("TimelockController deployed at", address(timelock));
        return timelock;
    }
}
