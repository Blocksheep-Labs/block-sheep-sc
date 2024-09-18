pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import {BlockSheep} from "../src/BlockSheep.sol";

contract AddRace is Script {
    BlockSheep internal blockSheep =
        BlockSheep(0xC31d4F4BfEe38421a1F7704D0632d6F2b15B44ef);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        BlockSheep.GameParams[] memory games = new BlockSheep.GameParams[](1);
        games[0].gameId = 0;
        games[0].questionIds = new uint256[](3);
        games[0].questionIds[0] = 0;
        games[0].questionIds[1] = 1;
        games[0].questionIds[2] = 2;

        int256[3][3] memory bullrunPoints = [
            [int256(-1), int256(-2), int256(3)],
            [int256(1), int256(0), int256(0)],
            [int256(-1), int256(1), int256(1)]
        ];

        blockSheep.addRace("Third", 1, 3, games, bullrunPoints);
        vm.stopBroadcast();
    }
}





