// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import {MockUSDC} from "src/MockUSDC.sol";

contract DeployMockUSDC is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new MockUSDC();
        vm.stopBroadcast();
    }
}
