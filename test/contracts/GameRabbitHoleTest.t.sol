// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {GameRabbitHole} from "../../src/GameRabbitHole.sol";

contract GameRabbitHoleTest is Test {
    GameRabbitHole game;

    address player1 = address(0x1);
    address player2 = address(0x2);
    address player3 = address(0x3);
    uint256 raceId = 1;
    uint256 roundIndex = 0;

    function setUp() public {
        game = new GameRabbitHole();
        game.initRace(raceId, "0x00"); // Initialize race in setup to avoid participation errors
    }

    function testInitRace() public {
        // Initialize a race
        // No assertion needed as initRace has no state change
    }

    function testMakeMove() public {
        // Player 1 makes a move
        vm.prank(player1);
        address[] memory inGame = new address[](2);
        inGame[0] = player2;
        inGame[1] = player3;
        bytes memory data = abi.encode(100, 50, roundIndex, player1, inGame);
        game.makeMove(raceId, data);
        
        // Check that player1's choice is recorded
        uint256[] memory choice = game.getUserChoices(raceId, player1);
        assertEq(choice[0], 100);
    }

    
    function testGetPoints() public {
        // Player 1 makes a move
        address[] memory inGame = new address[](2);
        inGame[0] = player2;
        inGame[1] = player3;
        bytes memory data = abi.encode(100, 50, roundIndex, player1, inGame);
        game.makeMove(raceId, data);
        
        // Check points for player1
        int256 points = game.getPoints(player1, raceId);
        assertEq(points, 0); // Initially, points should be 0
    }

    function testDistribute() public {
        // Simulate moves for players
        roundIndex = 0;

        // player1 makes move
        address[] memory inGame1 = new address[](2);
        inGame1[0] = player2;
        inGame1[1] = player3;
        bytes memory data1 = abi.encode(3, 7, roundIndex, player1, inGame1);
        vm.prank(player1);
        game.makeMove(raceId, data1);
        
        // player2 makes move
        address[] memory inGame2 = new address[](2);
        inGame2[0] = player1;
        inGame2[1] = player3;
        bytes memory data2 = abi.encode(2, 8, roundIndex, player2, inGame2);
        vm.prank(player2);
        game.makeMove(raceId, data2);

        // player3 makes move
        address[] memory inGame3 = new address[](2);
        inGame3[0] = player1;
        inGame3[1] = player3;
        bytes memory data3 = abi.encode(0, 10, roundIndex, player3, inGame3);
        vm.prank(player3);
        game.makeMove(raceId, data3);

        // player 3 finishes game and should get 1 point
        game.distribute(raceId, abi.encode(player3));

        int256 pointsPlayer3 = game.getPoints(player3, raceId);
        assertEq(pointsPlayer3, 1);

        roundIndex = 1;


        // player1 makes move
        address[] memory inGame4 = new address[](1);
        inGame4[0] = player2;
        bytes memory data4 = abi.encode(3, 4, roundIndex, player1, inGame4);
        vm.prank(player1);
        game.makeMove(raceId, data4);
        
        // player2 makes move
        address[] memory inGame5 = new address[](1);
        inGame5[0] = player1;
        bytes memory data5 = abi.encode(2, 6, roundIndex, player2, inGame5);
        vm.prank(player2);
        game.makeMove(raceId, data5);

        // player 2 finishes game and should get 2 points
        game.distribute(raceId, abi.encode(player2));
        int256 pointsPlayer2 = game.getPoints(player2, raceId);
        assertEq(pointsPlayer2, 2);


        // player 1 finishes game and should get 3 points
        game.distribute(raceId, abi.encode(player1));
        int256 pointsPlayer1 = game.getPoints(player1, raceId);
        assertEq(pointsPlayer1, 3);
    }

    function testGetUserChoices() public {
        // Player 1 makes a move
        address[] memory inGame = new address[](2);
        inGame[0] = player2;
        inGame[1] = player3;

        vm.prank(player1);
        bytes memory data = abi.encode(100, 50, roundIndex, player1, inGame);
        game.makeMove(raceId, data);
        
        // Check user choices
        uint256[] memory choices = game.getUserChoices(raceId, player1);
        require(choices.length > 0, "Player has no choices"); // Ensure choices exist
        assertEq(choices[0], 100);
    }

    function testGetRules() public view {
        // Check rules for a race
        bytes memory rules = game.getRules(raceId);
        assertEq(abi.decode(rules, (uint256)), raceId);
    }
}
