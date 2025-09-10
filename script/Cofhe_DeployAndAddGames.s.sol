// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";

// games
import {GameUnderdog} from "../src/fhe/GameUnderdog.sol";
import {BlockSheep} from "../src/fhe/BlockSheep.sol";


contract DeployGames is Script {
    function run(address blockSheepAddress) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // get deployed contract by address
        BlockSheep bls = BlockSheep(blockSheepAddress);
        console.log("BlockSheep at:", address(bls));

        GameUnderdog underdog = new GameUnderdog();
        console.log("GameUnderdog deployed at:", address(underdog));

        bls.registerContract("UNDERDOG", address(underdog));

        vm.stopBroadcast();
    }
}

