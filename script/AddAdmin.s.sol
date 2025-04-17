// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/BlockSheep.sol";
import "../lib/forge-std/src/Script.sol";

contract AddAdmin is Script {
    BlockSheep internal blockSheep =
        BlockSheep(0x2E47e70a19363b0fC2C899cbfab2A7c00eB44A5D);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        blockSheep.setAdminRights(0x5b01632e5942e80084451BD47184cDa1169e1555, true);

        vm.stopBroadcast();
    }
}