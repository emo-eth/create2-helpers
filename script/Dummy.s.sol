// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script, console2 } from "forge-std/Script.sol";
import { BaseCreate2Script } from "src/BaseCreate2Script.sol";
import { StdChains } from "forge-std/StdChains.sol";

contract dummy is BaseCreate2Script {
    function run() public {
        setChain(
            "example", StdChains.ChainData({ name: "Example Chain", chainId: 12345, rpcUrl: vm.rpcUrl("example") })
        );
        runOnNetworks(deploy, vm.envString("NETWORKS", ","));
    }

    function deploy() public pure returns (address) {
        return address(0);
    }
}
