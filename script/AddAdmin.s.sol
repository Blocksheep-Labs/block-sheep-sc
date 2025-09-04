// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/BlockSheep.sol";
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


// 0x37938ef05d81CCd598Db71546A4BAC1Ad9B5C25E
// 0x62001a7716CDbEC5eE7063a64672f91922Bcf1fB