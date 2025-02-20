// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/BlockSheep.sol";
import "../lib/forge-std/src/Script.sol";

contract AddAdmin is Script {
    BlockSheep internal blockSheep =
        BlockSheep(0x4b1104dcB19f04a353AE4e704f07d61ba2325069);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        blockSheep.setAdminRights(0x0e7f5b922AE381a532F80BFd145CEb2C382F9970, true);

        vm.stopBroadcast();
    }
}