// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {GameBullrun} from "../../src/GameBullrun.sol";

contract GameBullrunTest is Test {
    GameBullrun public game;
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);
    uint256 public raceId = 1;

    function setUp() public {
        game = new GameBullrun();
        
        // Initialize points matrix for the game
        // Example matrix where:
        // [0][0] = 0,  [0][1] = -1, [0][2] = 1
        // [1][0] = 1,  [1][1] = 0,  [1][2] = -1
        // [2][0] = -1, [2][1] = 1,  [2][2] = 0
        int256[3][3] memory points = [
            [int256(0), int256(-1), int256(1)],
            [int256(1), int256(0), int256(-1)],
            [int256(-1), int256(1), int256(0)]
        ];
        
        game.initRace(raceId, abi.encode(points));
    }

    function testInitRace() public {
        // Test if the rules were properly set
        bytes memory rules = game.getRules(raceId);
        int256[3][3] memory decodedRules = abi.decode(rules, (int256[3][3]));
        
        assertEq(decodedRules[0][1], -1);
        assertEq(decodedRules[1][0], 1);
        assertEq(decodedRules[2][2], 0);
    }

    function testMakeMove() public {
        // Alice makes a move against Bob
        vm.prank(alice);
        game.makeMove(raceId, abi.encode(0, bob));

        // Verify Alice's choice
        uint256[] memory aliceChoices = game.getUserChoices(raceId, alice);
        assertEq(aliceChoices.length, 0); // Choices are only recorded after distribution
    }

    function testCannotPlayAgainstSelf() public {
        vm.prank(alice);
        vm.expectRevert("Cannot play against yourself");
        game.makeMove(raceId, abi.encode(0, alice));
    }

    function testCannotPlayWithSameOpponentTwice() public {
        // First move
        vm.prank(alice);
        game.makeMove(raceId, abi.encode(0, bob));

        // Try to play with same opponent again
        vm.prank(alice);
        vm.expectRevert("Already played with this opponent");
        game.makeMove(raceId, abi.encode(1, bob));
    }

    function testDistributePoints() public {
        // Alice makes a move against Bob
        vm.prank(alice);
        game.makeMove(raceId, abi.encode(0, bob));

        // Bob makes a move against Alice
        vm.prank(bob);
        game.makeMove(raceId, abi.encode(1, alice));

        // Distribute points
        vm.prank(alice);
        game.distribute(raceId, abi.encode(bob));

        // Check points
        int256 alicePoints = game.getPoints(alice, raceId);
        int256 bobPoints = game.getPoints(bob, raceId);
        
        assertEq(alicePoints, -1); // Based on the points matrix [0][1] = -1
        assertEq(bobPoints, 1);    // Based on the points matrix [1][0] = 1
    }

    function testDistributeWhenOnePlayerDidNotMove() public {
        // Only Alice makes a move
        vm.prank(alice);
        game.makeMove(raceId, abi.encode(0, bob));

        // Distribute points
        vm.prank(alice);
        game.distribute(raceId, abi.encode(bob));

        // Check points
        int256 alicePoints = game.getPoints(alice, raceId);
        int256 bobPoints = game.getPoints(bob, raceId);
        
        assertEq(alicePoints, 1);  // Alice should get +1 for making a move
        assertEq(bobPoints, -1);   // Bob should get -1 for not making a move
    }

    function testGetWinner() public {
        // Set up a scenario with multiple players
        vm.prank(alice);
        game.makeMove(raceId, abi.encode(0, bob));
        vm.prank(bob);
        game.makeMove(raceId, abi.encode(1, alice));
        vm.prank(alice);
        game.distribute(raceId, abi.encode(bob));

        vm.prank(bob);
        game.makeMove(raceId, abi.encode(1, charlie));
        vm.prank(charlie);
        game.makeMove(raceId, abi.encode(2, bob));
        vm.prank(bob);
        game.distribute(raceId, abi.encode(charlie));

        (address[] memory winners, int256[] memory points) = game.getWinner(raceId);
        
        // Ensure winners and points arrays are not empty before accessing
        require(winners.length > 0, "No winners found");
        require(points.length > 0, "No points found");
        
        // Verify the winners array contains 3 addresses
        assertEq(winners.length, 3);
        // Verify the points array contains 3 values
        assertEq(points.length, 3);
    }
}
