pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {GameRabbitHole} from"../../src/GameRabbitHole.sol"; // Adjust the path as necessary

contract GameRabbitHoleTest is Test {
    GameRabbitHole game;

    address player1 = address(0x1);
    address player2 = address(0x2);
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
        bytes memory data = abi.encode(100, 50, roundIndex);
        game.makeMove(raceId, data);
        
        // Check that player1's choice is recorded
        uint256[] memory choice = game.getUserChoices(raceId, player1);
        assertEq(choice[0], 100);
    }

    function testGetPoints() public {
        // Player 1 makes a move
        bytes memory data = abi.encode(100, 50, roundIndex);
        game.makeMove(raceId, data);
        
        // Check points for player1
        int256 points = game.getPoints(player1, raceId);
        assertEq(points, 0); // Initially, points should be 0
    }

    function testDistribute() public {
        // Simulate moves for players
        bytes memory data1 = abi.encode(100, 50, roundIndex);
        vm.prank(player1);
        game.makeMove(raceId, data1);
        
        bytes memory data2 = abi.encode(200, 30, roundIndex);
        vm.prank(player2);
        game.makeMove(raceId, data2);
        
        // Distribute results
        game.distribute(raceId, "0x00");
        
        // Check winners
        (address[] memory winners, ) = game.getWinner(raceId);
        assertEq(winners[0], player2); // Assuming player2 has the highest score
    }

    function testGetUserChoices() public {
        // Player 1 makes a move
        vm.prank(player1);
        bytes memory data = abi.encode(100, 50, roundIndex);
        game.makeMove(raceId, data);
        
        // Check user choices
        uint256[] memory choices = game.getUserChoices(raceId, player1);
        require(choices.length > 0, "Player has no choices"); // Ensure choices exist
        assertEq(choices[0], 100);
    }

    function testGetRules() public {
        // Check rules for a race
        bytes memory rules = game.getRules(raceId);
        assertEq(abi.decode(rules, (uint256)), raceId);
    }
}
