pragma solidity ^0.8.20;

import {BlockSheep} from "src/BlockSheep.sol";
import {BlockSheepTest} from "test/BlockSheep.t.sol";
import "forge-std/console.sol";

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
        blockSheep.distributeReward(0, 0, 0);

        uint256 winnerScore = blockSheep.getScoreAtGameOfUser(0, 0, playerTwo);
        assertEq(winnerScore, 2);
    }
}
