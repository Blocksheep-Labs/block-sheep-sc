// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { GameWhaleteeth } from "../../src/GameWhaleteeth.sol";


contract GameWhaleteethTest is Test {
    GameWhaleteeth game;
    
    address owner = address(0x1);
    address player1 = address(0x2);
    address player2 = address(0x3);
    address player3 = address(0x4);
    
    uint256 raceId = 1;

    function setUp() public {
        vm.prank(owner);
        game = new GameWhaleteeth();
    }

    function testDistributePoints() public {
        address[] memory players = new address[](2);
        players[0] = player1;
        players[1] = player2;
        
        int256[] memory points = new int256[](2);
        points[0] = 100;
        points[1] = 200;
        
        bytes memory data = abi.encode(players, points);
        
        game.distribute(raceId, data);
        
        assertEq(game.getPoints(player1, raceId), 100 * game.BPS());
        assertEq(game.getPoints(player2, raceId), 200 * game.BPS());
    }

    function testChangeTyresEffect() public {
        address[] memory players = new address[](1);
        players[0] = player1;
        
        int256[] memory points = new int256[](1);
        points[0] = 100;
        
        bytes memory data = abi.encode(players, points);
        game.distribute(raceId, data);
        
        assertEq(game.getPoints(player1, raceId), 100 * game.BPS());
        
        game.changeTyres(raceId, player1);
        
        assertEq(game.getPoints(player1, raceId), 250 * game.BPS());
        assertTrue(game.WHALETEETH_changedTyresBeforeTheGame(raceId, player1));
    }

    function testGetWinner() public {
        address[] memory players = new address[](3);
        players[0] = player1;
        players[1] = player2;
        players[2] = player3;
        
        int256[] memory points = new int256[](3);
        points[0] = 300; // player1
        points[1] = 100; // player2
        points[2] = 200; // player3
        
        bytes memory data = abi.encode(players, points);
        game.distribute(raceId, data);

        (address[] memory winners, ) = game.getWinner(raceId);
        assertEq(winners.length, 3);
        
        game.changeTyres(raceId, player3);
        
        (address[] memory winnersAfter, int256[] memory winnerPoints) = game.getWinner(raceId);
        
        assertEq(winnersAfter.length, 3);
        assertEq(winnerPoints.length, 3);
        
        assertEq(winnersAfter[0], player3);
        assertEq(winnerPoints[0], 500 * game.BPS());
        
        assertEq(winnersAfter[1], player1);
        assertEq(winnerPoints[1], 300 * game.BPS());
        
        assertEq(winnersAfter[2], player2);
        assertEq(winnerPoints[2], 100 * game.BPS());
    }

    function testDistributeWithMismatchedArrays() public {
        address[] memory players = new address[](2);
        players[0] = player1;
        players[1] = player2;
        
        int256[] memory points = new int256[](1); 
        points[0] = 100;
        
        bytes memory data = abi.encode(players, points);
        
        vm.expectRevert("Mismatched data length");
        game.distribute(raceId, data);
    }
}