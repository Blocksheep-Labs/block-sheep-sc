pragma solidity ^0.8.20;

import {BlockSheep} from "src/BlockSheep.sol";
import {BlockSheepTest} from "test/BlockSheep.t.sol";

contract SubmitAnswerTest is BlockSheepTest {
    function setUp() public override {
        super.setUp();
        vm.startPrank(owner);
        addGame();

        addQuestions();
        addRaceInternal();
        vm.stopPrank();
        registerInternal(playerOne, 0);
        registerInternal(playerTwo, 0);
        registerInternal(playerThree, 0);
    }

    function test_SubmitAnswer() public {
        vm.startPrank(playerOne);
        uint8[] memory answerIds = new uint8[](3);
        answerIds[0] = 1;
        answerIds[1] = 1;
        answerIds[2] = 0;
        blockSheep.submitAnswers(0, 0, answerIds);
        vm.stopPrank();
    }
}
