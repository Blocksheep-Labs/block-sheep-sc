pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {BlockSheep} from "src/BlockSheep.sol";
import {MockUSDC} from "src/test/MockUSDC.sol";

contract BlockSheepTest is Test {
    BlockSheep internal blockSheep;
    MockUSDC internal usdc;

    address internal owner = address(1);
    address internal playerOne = address(2);
    address internal playerTwo = address(3);
    address internal playerThree = address(4);
    address internal playerFour = address(5);
    uint256 internal cost = 10e6;
    uint256 internal mintAmount = 100e6;

    function setUp() public virtual {
        usdc = new MockUSDC();
        blockSheep = new BlockSheep(address(usdc), owner, cost);
        usdc.mint(playerOne, mintAmount);
        usdc.mint(playerTwo, mintAmount);
        usdc.mint(playerThree, mintAmount);
        usdc.mint(playerFour, mintAmount);
    }

    function addGame() public virtual {
        blockSheep.addGameName("First Game");
    }

    function addQuestions() public virtual {
        blockSheep.addQuestions(getQuestionsInternal());
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

    function addRaceInternal() internal {
        BlockSheep.GameParams[] memory games = new BlockSheep.GameParams[](1);
        games[0].gameId = 0;
        games[0].questionIds = new uint256[](3);
        games[0].questionIds[0] = 0;
        games[0].questionIds[1] = 1;
        games[0].questionIds[2] = 2;
        blockSheep.addRace("Race 1", uint64(block.timestamp + 2 hours), games);
    }

    function registerInternal(address user, uint256 raceId) internal {
        (, , , uint8 numberOfQuestions, , , , ) = blockSheep.getRaces(raceId);
        uint256 amount = blockSheep.COST() * numberOfQuestions;
        vm.startPrank(user);
        usdc.approve(address(blockSheep), amount);
        blockSheep.deposit(amount);
        blockSheep.register(raceId);
        vm.stopPrank();
    }

    function submitAnswer(
        address user,
        uint256 raceId,
        uint8 gameIndex,
        uint8 qIndex,
        uint8 aId
    ) internal {
        vm.startPrank(user);
        blockSheep.submitAnswer(raceId, gameIndex, qIndex, aId);
        vm.stopPrank();
    }
}
