// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/BlockSheep.sol";
import "../lib/forge-std/src/Script.sol";

contract AddAdmin is Script {
    BlockSheep internal blockSheep =
        BlockSheep(0x04E479005685D866b10c0DeEC5C679f633d34140);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        blockSheep.setAdminRights(0xC5B7c26c237b55B33CCc6279A85Cd030d170C822, true);

        vm.stopBroadcast();
    }
}