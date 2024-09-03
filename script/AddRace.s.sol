pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import {BlockSheep} from "../src/BlockSheep.sol";

contract AddRace is Script {
    BlockSheep internal blockSheep =
        BlockSheep(0xE9D3Df4EEb0940997cC95CDCCD61eC5C2cCa7A57);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        BlockSheep.GameParams[] memory games = new BlockSheep.GameParams[](1);
        games[0].gameId = 0;
        games[0].questionIds = new uint256[](3);
        games[0].questionIds[0] = 0;
        games[0].questionIds[1] = 1;
        games[0].questionIds[2] = 2;

        blockSheep.addRace("Third", 1, 3, games);
        vm.stopBroadcast();
    }
}
