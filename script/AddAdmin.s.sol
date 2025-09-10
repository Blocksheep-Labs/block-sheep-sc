// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/basic/BlockSheep.sol";
import "../lib/forge-std/src/Script.sol";

contract AddAdmin is Script {
    function run(address blockSheep, address newAdmin) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        BlockSheep bls = BlockSheep(blockSheep);
        bls.setAdminRights(newAdmin, true);

        vm.stopBroadcast();
    }
}

// 0x383Eb944a4748cf4Ed0A492a4d6001dA471E5A58
