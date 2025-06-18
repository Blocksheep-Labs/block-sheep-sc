// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import { Test } from "forge-std/Test.sol";
import { GameUnderdog } from "../../src/GameUnderdog.sol";

contract GameUnderdogTest is Test {
    GameUnderdog game;

    address player1 = address(0x1);
    address player2 = address(0x2);
    address player3 = address(0x3);
    address player4 = address(0x4);
    uint256 raceId = 1;

    function setUp() public {
        game = new GameUnderdog();
        
        // Create a temporary memory array
        GameUnderdog.QuestionInfo[] memory questions = new GameUnderdog.QuestionInfo[](3);

        // Populate the memory array
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

        questions[2].content = "Question content 3";
        questions[2].answers = new string[](2);
        questions[2].answers[0] = "Answer 1";
        questions[2].answers[1] = "Answer 2";
        questions[2].imgUrl = "url3";

        // Encode the questions array before passing it to initRace
        game.initRace(raceId, abi.encode(questions));

        assertEq(questions.length, 3);
        assertEq(keccak256(abi.encodePacked(questions[0].content)), keccak256(abi.encodePacked("Question content 1")));
    }

    function testInitRace() public {
        // tested at setUp
    }

    function testMakeMove() public {
        // Player 1 makes a move
        vm.prank(player1);
        bytes memory data = abi.encode(uint8(0), uint8(1), player1); // Question index 0, answer index 1
        game.makeMove(raceId, data);
        
        // Check that player1's choice is recorded
        uint256[] memory choices = game.getUserChoices(raceId, player1);
        assertEq(choices[0], 1); // Assuming answer index 1 is chosen
    }

    function testGetUserChoices() public {
        // Player 1 makes a move
        vm.prank(player1);
        bytes memory data = abi.encode(uint8(0), uint8(1), player1); // Question index 0, answer index 1
        game.makeMove(raceId, data);
        
        // Check user choices
        uint256[] memory choices = game.getUserChoices(raceId, player1);
        assertEq(choices[0], 1); // Check the first choice
    }

    function testGetPoints() public {
        // Player 1 makes a move
        vm.prank(player1);
        bytes memory data = abi.encode(uint8(0), uint8(1), player1); // Question index 0, answer index 1
        game.makeMove(raceId, data);
        
        // Check points for player1
        int256 points = game.getPoints(player1, raceId);
        assertEq(points, 0); // Initially, points should be 0
    }

    function testDistributeAndGetWInners() public {
        // Simulate moves for players
        // 1 st question
        vm.prank(player1);
        bytes memory data10 = abi.encode(uint8(0), uint8(1), player1); // Player 1's move
        game.makeMove(raceId, data10);

        vm.prank(player2);
        bytes memory data20 = abi.encode(uint8(0), uint8(0), player2); // Player 2's move
        game.makeMove(raceId, data20);

        vm.prank(player3);
        bytes memory data30 = abi.encode(uint8(0), uint8(0), player3); // Player 3's move
        game.makeMove(raceId, data30);

        vm.prank(player4);
        bytes memory data40 = abi.encode(uint8(0), uint8(0), player4); // Player 4's move
        game.makeMove(raceId, data40);

        // 2 nd question
        vm.prank(player1);
        bytes memory data11 = abi.encode(uint8(1), uint8(0), player1); // Player 1's move
        game.makeMove(raceId, data11);

        vm.prank(player2);
        bytes memory data21 = abi.encode(uint8(1), uint8(1), player2); // Player 2's move
        game.makeMove(raceId, data21);

        vm.prank(player3);
        bytes memory data31 = abi.encode(uint8(1), uint8(0), player3); // Player 3's move
        game.makeMove(raceId, data31);

        vm.prank(player4);
        bytes memory data41 = abi.encode(uint8(1), uint8(0), player4); // Player 4's move
        game.makeMove(raceId, data41);

        // 3 rd question
        vm.prank(player1);
        bytes memory data12 = abi.encode(uint8(2), uint8(0), player1); // Player 1's move
        game.makeMove(raceId, data12);

        vm.prank(player2);
        bytes memory data22 = abi.encode(uint8(2), uint8(1), player2); // Player 2's move
        game.makeMove(raceId, data22);

        vm.prank(player3);
        bytes memory data32 = abi.encode(uint8(2), uint8(0), player3); // Player 3's move
        game.makeMove(raceId, data32);

        vm.prank(player4);
        bytes memory data42 = abi.encode(uint8(2), uint8(0), player4); // Player 4's move
        game.makeMove(raceId, data42);
        
        // Distribute results
        bytes memory dataDistribute = abi.encode(uint8(0), true); // Player 3's move
        game.distribute(raceId, dataDistribute);
        
        // Check points after distribution
        int256 points1 = game.getPoints(player1, raceId);
        int256 points2 = game.getPoints(player2, raceId);
        int256 points3 = game.getPoints(player3, raceId);
        
        // Assuming player 1's answer is correct and player 2's is not
        assertEq(points1, 1 * game.BPS()); // Player 1 should get 1 point
        assertEq(points2, 2 * game.BPS()); // Player 2 should get 0 points
        assertEq(points3, 0); // Player 3 should get 0 points


        (address[] memory users, int256[] memory points) = game.getWinner(raceId);
        assertEq(player2, users[0]);
        assertEq(points[0], 2000);

        assertEq(player1, users[1]);
        assertEq(points[1], 1000);

        assertEq(player3, users[2]);
        assertEq(points[2], 0);
    }

    function testGetRules() public view {
        // Check rules for a race
        bytes memory rules = game.getRules(raceId);
        GameUnderdog.QuestionInfoReturnType[] memory questionsInfo = abi.decode(rules, (GameUnderdog.QuestionInfoReturnType[]));
        assertEq(questionsInfo.length, 3);
        assertEq(
            keccak256(abi.encodePacked(questionsInfo[0].info.content)), 
            keccak256(abi.encodePacked("Question content 1"))
        );
    }
}