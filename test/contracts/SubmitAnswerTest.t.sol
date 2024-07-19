pragma solidity ^0.8.20;

import {BlockSheep} from "src/BlockSheep.sol";
import {BlockSheepTest} from "test/contracts/BlockSheep.t.sol";

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
        submitAnswer(playerOne, 0, 0, 0, 1);
    }
}
