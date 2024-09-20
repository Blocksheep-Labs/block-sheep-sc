// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {BlockSheep} from "src/BlockSheep.sol";
import {GAME_Bullrun} from "src/GAME_Bullrun.sol";
import {BlockSheepTest} from "test/contracts/BlockSheep.t.sol";


contract GAME_BullrunTest is BlockSheepTest {
    GAME_Bullrun internal gameBullrun;

    address internal admin = address(1);
    uint256 internal raceId = 0;

    function setUp() public virtual override {
        super.setUp();  // Call BlockSheepTest setup
        vm.startPrank(owner);
        addGame();
        addQuestions();
        addRaceInternal();
        vm.stopPrank();

        // Setting up the BlockSheep for admin access
        vm.startPrank(admin);
        blockSheep.setAdminRights(admin, true);
        vm.stopPrank();
    }

    function testMakesChoice() public {
        // Player one makes a choice first
        vm.startPrank(playerOne);
        blockSheep.BULLRUN_makeChoice(raceId, 1, playerTwo); // makes a choice (1), "waits" for opponent choice
        vm.stopPrank();

        // Now player two makes a choice
        vm.startPrank(playerTwo);
        blockSheep.BULLRUN_makeChoice(raceId, 2, playerOne); // makes a choice (2), assigns all the points for two (perks indexes: user1: 1,2  user2: 2,1)
        vm.stopPrank();


        vm.startPrank(playerOne);
        blockSheep.BULLRUN_distribute(raceId, playerTwo);
        vm.stopPrank();

        vm.startPrank(playerTwo);
        blockSheep.BULLRUN_distribute(raceId, playerOne);
        vm.stopPrank();

        // Verify points were updated correctly
        int256 playerOnePoints = blockSheep.BULLRUN_getAmountOfPointsPerGame(playerOne, raceId);
        int256 playerTwoPoints = blockSheep.BULLRUN_getAmountOfPointsPerGame(playerTwo, raceId);


        // based on old matrix 
        assertEq(playerOnePoints, 0);
        assertEq(playerTwoPoints, 1);
    }

    function testAdminSetPointsPerPerks() public {
        // Admin sets the points matrix
        vm.startPrank(admin);
        int256[3][3] memory pointsMatrix = [
            [int256(1), int256(2), int256(3)],
            [int256(3), int256(2), int256(1)],
            [int256(1), int256(3), int256(2)]
        ];
        blockSheep.BULLRUN_setPointsPerPerksForRace(raceId, pointsMatrix);
        vm.stopPrank();

        // Check the points were set correctly
        int256 expectedPoint1 = blockSheep.BULLRUN_pointsPerPerks(raceId, 0, 0); assertEq(expectedPoint1, 1);
        int256 expectedPoint2 = blockSheep.BULLRUN_pointsPerPerks(raceId, 0, 1); assertEq(expectedPoint2, 2);
        int256 expectedPoint3 = blockSheep.BULLRUN_pointsPerPerks(raceId, 0, 2); assertEq(expectedPoint3, 3);
        int256 expectedPoint4 = blockSheep.BULLRUN_pointsPerPerks(raceId, 1, 0); assertEq(expectedPoint4, 3);
        int256 expectedPoint5 = blockSheep.BULLRUN_pointsPerPerks(raceId, 1, 1); assertEq(expectedPoint5, 2);
        int256 expectedPoint6 = blockSheep.BULLRUN_pointsPerPerks(raceId, 1, 2); assertEq(expectedPoint6, 1);
        int256 expectedPoint7 = blockSheep.BULLRUN_pointsPerPerks(raceId, 2, 0); assertEq(expectedPoint7, 1);
        int256 expectedPoint8 = blockSheep.BULLRUN_pointsPerPerks(raceId, 2, 1); assertEq(expectedPoint8, 3);
        int256 expectedPoint9 = blockSheep.BULLRUN_pointsPerPerks(raceId, 2, 2); assertEq(expectedPoint9, 2);
    }

    function testNonAdminCannotSetPointsPerPerks() public {
        // Trying to set points from a non-admin address
        vm.startPrank(playerOne);
        int256[3][3] memory pointsMatrix = [
            [int256(1), int256(2), int256(3)],
            [int256(3), int256(2), int256(1)],
            [int256(1), int256(3), int256(2)]
        ];
        vm.expectRevert("Sender is not an admin");
        blockSheep.BULLRUN_setPointsPerPerksForRace(raceId, pointsMatrix);
        vm.stopPrank();
    }

    function getUserPerk(uint256 raceId, address user) internal view returns (uint256) {
        uint256[] memory points = blockSheep.BULLRUN_getUserChoicesIndexes(raceId, user);
        return points[0];
    }
}
