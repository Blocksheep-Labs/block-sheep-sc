// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import {BlockSheepPayments} from "src/BlockSheepPayments.sol";

contract DeployPayments is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        BlockSheepPayments payments = new BlockSheepPayments(
            0xaf88d065e77c8cC2239327C5EDb3A432268e5831, // USDC contract address
            vm.addr(deployerPrivateKey)
        );

        console.log("Payments deployed at", address(payments));
        vm.stopBroadcast();
    }
}
