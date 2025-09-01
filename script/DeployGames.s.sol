// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";

// games
import {GameBullrun} from "../src/GameBullrun.sol";
import {GameRabbitHole} from "../src/GameRabbitHole.sol";
import {GameUnderdog} from "../src/GameUnderdog.sol";
import {GameWhaleteeth} from "../src/GameWhaleteeth.sol";

contract DeployGames is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        GameBullrun bullrun = new GameBullrun();
        GameRabbitHole rabbitHole = new GameRabbitHole();
        GameUnderdog underdog = new GameUnderdog();
        GameWhaleteeth whaleteeth = new GameWhaleteeth();

        console.log("GameBullrun deployed at:", address(bullrun));
        console.log("GameRabbitHole deployed at:", address(rabbitHole));
        console.log("GameUnderdog deployed at:", address(underdog));
        console.log("GameWhaleteeth deployed at:", address(whaleteeth));

        vm.stopBroadcast();
    }
}

