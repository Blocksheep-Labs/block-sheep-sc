// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import {BlockSheep} from "../src/fhe/BlockSheep.sol";

contract Cofhe_DeployBlockSheep is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        BlockSheep bls = new BlockSheep(
            vm.addr(deployerPrivateKey)
        );

        console.log("BlockSheep deployed at", address(bls));
        vm.stopBroadcast();
    }
}
