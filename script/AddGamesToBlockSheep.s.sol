// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";

import {BlockSheep} from "../src/BlockSheep.sol";

// games
import {GameBullrun} from "../src/GameBullrun.sol";
import {GameRabbitHole} from "../src/GameRabbitHole.sol";
import {GameUnderdog} from "../src/GameUnderdog.sol";
import {GameWhaleteeth} from "../src/GameWhaleteeth.sol";


contract AddGamesToBlockSheep is Script {
    function run(
        address blockSheepAddress, // MAIN CONTRACT
        address bullrunAddress,    // BULLRUN GAME
        address rabbitHoleAddress, // RABBITHOLE GAME
        address underdogAddress,   // UNDERDOG GAME
        address whaleteethAddress  // WHALETEETH GAME
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // get deployed contract by address
        BlockSheep bls = BlockSheep(blockSheepAddress);

        console.log("BlockSheep at:", address(bls));

        // register games
        bls.registerContract("BULLRUN", bullrunAddress);
        bls.registerContract("RABBITHOLE", rabbitHoleAddress);
        bls.registerContract("UNDERDOG", underdogAddress);
        bls.registerContract("WHALETEETH", whaleteethAddress);

        vm.stopBroadcast();
    }
}

