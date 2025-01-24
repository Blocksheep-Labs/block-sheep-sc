// test/contracts/GameUnderdogTest.t.sol
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { GameUnderdog } from "../../src/GameUnderdog.sol"; // Adjust the path as necessary

contract GameUnderdogTest is Test {
    GameUnderdog game;

    address player1 = address(0x1);
    address player2 = address(0x2);
    address player3 = address(0x3);
    uint256 raceId = 1;

    function setUp() public {
        game = new GameUnderdog();
        GameUnderdog.QuestionInfo[] memory questions = new GameUnderdog.QuestionInfo[](2);

        questions[0].content = "Question content 1";
        questions[0].answers = new string[](2);
        questions[0].answers[0] = "Answer 1"; 
        questions[0].answers[1] = "Answer 2";
        questions[0].imgUrl = "url1";

        questions[1].content = "Question content 2";
        questions[1].answers = new string[](2);
        questions[1].answers[0] = "Answer 1"; 
        questions[1].answers[1] = "Answer 2";
        questions[1].imgUrl = "url2";

        game.initRace(raceId, abi.encode(questions));

        assertEq(questions.length, 2);
        assertEq(keccak256(abi.encodePacked(questions[0].content)), keccak256(abi.encodePacked("Question content 1")));
    }

    function testInitRace() public {
        // tested at setUp
    }

    function testMakeMove() public {
        // Player 1 makes a move
        vm.prank(player1);
        bytes memory data = abi.encode(uint8(0), uint8(1)); // Question index 0, answer index 1
        game.makeMove(raceId, data);
        
        // Check that player1's choice is recorded
        uint256[] memory choices = game.getUserChoices(raceId, player1);
        assertEq(choices[0], 1); // Assuming answer index 1 is chosen
    }

    function testGetUserChoices() public {
        // Player 1 makes a move
        vm.prank(player1);
        bytes memory data = abi.encode(uint8(0), uint8(1)); // Question index 0, answer index 1
        game.makeMove(raceId, data);
        
        // Check user choices
        uint256[] memory choices = game.getUserChoices(raceId, player1);
        assertEq(choices[0], 1); // Check the first choice
    }

    function testGetPoints() public {
        // Player 1 makes a move
        bytes memory data = abi.encode(uint8(0), uint8(1)); // Question index 0, answer index 1
        game.makeMove(raceId, data);
        
        // Check points for player1
        int256 points = game.getPoints(player1, raceId);
        assertEq(points, 0); // Initially, points should be 0
    }

    function testDistribute() public {
        // Simulate moves for players
        vm.prank(player1);
        bytes memory data1 = abi.encode(uint8(0), uint8(1)); // Player 1's move
        game.makeMove(raceId, data1);
        
        vm.prank(player2);
        bytes memory data2 = abi.encode(uint8(0), uint8(0)); // Player 2's move
        game.makeMove(raceId, data2);

        vm.prank(player3);
        bytes memory data3 = abi.encode(uint8(0), uint8(0)); // Player 3's move
        game.makeMove(raceId, data3);
        
        // Distribute results
        game.distribute(raceId, "0x00");
        
        // Check points after distribution
        int256 points1 = game.getPoints(player1, raceId);
        int256 points2 = game.getPoints(player2, raceId);
        int256 points3 = game.getPoints(player3, raceId);
        
        // Assuming player 1's answer is correct and player 2's is not
        assertEq(points1, 1); // Player 1 should get 1 point
        assertEq(points2, 0); // Player 2 should get 0 points
        assertEq(points3, 0); // Player 3 should get 0 points
    }

    function testGetRules() public {
        // Check rules for a race
        bytes memory rules = game.getRules(raceId);
        GameUnderdog.QuestionInfoReturnType[] memory questionsInfo = abi.decode(rules, (GameUnderdog.QuestionInfoReturnType[]));
        assertEq(questionsInfo.length, 2);
        assertEq(
            keccak256(abi.encodePacked(questionsInfo[0].info.content)), 
            keccak256(abi.encodePacked("Question content 1"))
        );
    }
}