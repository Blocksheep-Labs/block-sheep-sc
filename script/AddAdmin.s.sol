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

//0xc662908Aa4d36899C8d82041a1255304391A8985
//0x37938ef05d81CCd598Db71546A4BAC1Ad9B5C25E