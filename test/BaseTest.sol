// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { PublicBaseCreate2 } from "./helpers/PublicBaseCreate2.sol";

contract BaseTest is Test {
    PublicBaseCreate2 test;

    function setUp() public virtual {
        test = new PublicBaseCreate2();
        (, uint256 key) = makeAddrAndKey("deployer");
    }
}
