pragma solidity ^0.8.20;

import {BlockSheep} from "src/BlockSheep.sol";
import {BlockSheepTest} from "test/contracts/BlockSheep.t.sol";


contract DistributeRewardTest is BlockSheepTest {
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
        submitAnswer(playerOne, 0, 0, 0, 1);
        submitAnswer(playerTwo, 0, 0, 0, 0);
        submitAnswer(playerThree, 0, 0, 0, 1);
    }

    function test_DistributeReward() public {
        uint8[1] memory fixedArray = [0];  // Fixed-size array with one element
        uint8[] memory dynamicArray = new uint8[](fixedArray.length);

        for (uint8 i = 0; i < fixedArray.length; i++) {
            dynamicArray[i] = fixedArray[i];
        }

        blockSheep.distributeReward(0, 0, dynamicArray);

        uint256 winnerScore = blockSheep.getScoreAtGameOfUser(0, 0, playerTwo);
        assertEq(winnerScore, 2);
    }
}
