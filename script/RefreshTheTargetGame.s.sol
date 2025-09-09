// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";

import {BlockSheep} from "../src/basic/BlockSheep.sol";

// games
import {GameBullrun} from "../src/basic/GameBullrun.sol";
import {GameRabbitHole} from "../src/basic/GameRabbitHole.sol";
import {GameUnderdog} from "../src/basic/GameUnderdog.sol";
import {GameWhaleteeth} from "../src/basic/GameWhaleteeth.sol";

contract RefreshTheTargetGame is Script {
                                            // WHALETEETH | UNDERDOG | RABBITHOLE | BULLRUN
    function run(address blockSheepAddress, string memory targetGame) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address targetAddress = address(0);

        // get deployed contract by address
        BlockSheep bls = BlockSheep(blockSheepAddress);

        console.log("BlockSheep at:", address(bls));

        bytes32 targetGamePacked = keccak256(abi.encodePacked(targetGame));

        if (targetGamePacked == keccak256(abi.encodePacked("BULLRUN"))) {
            GameBullrun bullrun = new GameBullrun();
            targetAddress = address(bullrun);
        }

        if (targetGamePacked == keccak256(abi.encodePacked("RABBITHOLE"))) {
            GameRabbitHole rabbitHole = new GameRabbitHole();
            targetAddress = address(rabbitHole);
        }

        if (targetGamePacked == keccak256(abi.encodePacked("UNDERDOG"))) {
            GameUnderdog underdog = new GameUnderdog();
            targetAddress = address(underdog);
        }

        if (targetGamePacked == keccak256(abi.encodePacked("WHALETEETH"))) {
            GameWhaleteeth whaleteeth = new GameWhaleteeth();
            targetAddress = address(whaleteeth);
        }

        if (targetAddress == address(0)) {
            revert("Invalid target contract name");
        }

        console.log(targetGame, "deployed at:", targetAddress);

        bls.registerContract(targetGame, targetAddress);

        console.log("Target updated for:", targetGame, targetAddress);

        vm.stopBroadcast();
    }
}

