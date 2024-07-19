pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import {BlockSheep} from "../src/BlockSheep.sol";

contract AddGameAndQuestions is Script {
    BlockSheep internal blockSheep =
        BlockSheep(0x755464031eC549df7B81701DB068E063D8A5fEeF);
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        blockSheep.addGameName("Quiz");
        blockSheep.addQuestions(getQuestionsInternal());
        vm.stopBroadcast();
    }

    function getQuestionsInternal()
        internal
        pure
        returns (BlockSheep.QuestionInfo[] memory questions)
    {
        questions = new BlockSheep.QuestionInfo[](3);
        questions[0].content = "Is it better to have nice or smart kids?";
        questions[0].answers = new string[](2);
        questions[0].answers[0] = "smart";
        questions[0].answers[1] = "nice";

        questions[1]
            .content = "Would you rather explore the depths of the ocean or outer space?";
        questions[1].answers = new string[](2);
        questions[1].answers[0] = "ocean";
        questions[1].answers[1] = "space";

        questions[2]
            .content = "Would you rather read minds or being able to teleport?";
        questions[2].answers = new string[](2);
        questions[2].answers[0] = "read";
        questions[2].answers[1] = "teleport";
    }
}
