pragma solidity ^0.8.20;
import "forge-std/console.sol";
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

        submitAnswer(playerOne, 0, 0, 0, 0);
        submitAnswer(playerOne, 0, 0, 1, 0);
        submitAnswer(playerOne, 0, 0, 2, 0);     // 2 points

        submitAnswer(playerTwo, 0, 0, 0, 1);
        submitAnswer(playerTwo, 0, 0, 1, 1);
        submitAnswer(playerTwo, 0, 0, 2, 0);     // 0 point

        submitAnswer(playerThree, 0, 0, 0, 1);
        submitAnswer(playerThree, 0, 0, 1, 1);
        submitAnswer(playerThree, 0, 0, 2, 1);   // 1 points
    }

    function test_DistributeReward() public {
        uint8[3] memory fixedArray = [0,1,2];  // Fixed-size array with 3 elements
        uint8[] memory dynamicArray = new uint8[](fixedArray.length);

        for (uint8 i = 0; i < fixedArray.length; i++) {
            dynamicArray[i] = fixedArray[i];
        }

        blockSheep.distributeReward(0, 0, dynamicArray, false, playerOne);
         blockSheep.distributeReward(0, 0, dynamicArray, false, playerTwo);
          blockSheep.distributeReward(0, 0, dynamicArray, false, playerThree);

        uint256 player1Score = blockSheep.getScoreAtGameOfUser(0, 0, playerOne, "underdog");
        uint256 player2Score = blockSheep.getScoreAtGameOfUser(0, 0, playerTwo, "underdog");
        uint256 player3Score = blockSheep.getScoreAtGameOfUser(0, 0, playerThree, "underdog");

        console.log("player1Score");
        console.log(player1Score);
        console.log("player2Score");
        console.log(player2Score);
        console.log("player3Score");
        console.log(player3Score);

        assertEq(player1Score, 2);
        assertEq(player2Score, 0);
        assertEq(player3Score, 1);
    }
}
