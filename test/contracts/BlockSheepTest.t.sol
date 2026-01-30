// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {BlockSheep} from "../../src/BlockSheep.sol";
import {MockUSDC} from "../../src/MockUSDC.sol";

// game contracts
import {GameBullrun} from "../../src/GameBullrun.sol";
import {GameRabbitHole} from "../../src/GameRabbitHole.sol";
import {GameUnderdog} from "../../src/GameUnderdog.sol";

contract BlockSheepTest is Test {
    BlockSheep bls;

    address owner = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);
    address user3 = address(0x4);
    address user4 = address(0x5);
    address user5 = address(0x6);
    address user6 = address(0x7);
    address user7 = address(0x8);

    uint8 decimals = 1;

    string[] screens; // screens sequence
    int256[3][3] points; // for bullrun
    GameUnderdog.QuestionInfo[] questions; // for underdog;

    function setUp() public {
        vm.prank(owner);

        bls = new BlockSheep(owner);

        // register games
        GameUnderdog underdog = new GameUnderdog();
        GameRabbitHole rabbitHole = new GameRabbitHole();
        GameBullrun bullrun = new GameBullrun();

        bls.registerContract("UNDERDOG", address(underdog));
        bls.registerContract("RABBITHOLE", address(rabbitHole));
        bls.registerContract("BULLRUN", address(bullrun));

        // screens setup
        screens = new string[](1);
        screens[0] = "FIRST_TEST_SCREEN";

        // bullrun init
        points = [
            [int256(0), int256(-1), int256(1)],
            [int256(1), int256(0), int256(-1)],
            [int256(-1), int256(1), int256(0)]
        ];

        // underdog init
        questions = new GameUnderdog.QuestionInfo[](1);

        questions[0].content = "Question content 1";
        questions[0].answers = new string[](2);
        questions[0].answers[0] = "Answer 1";
        questions[0].answers[1] = "Answer 2";
        questions[0].imgUrl = "url1";
    }

    function testRegisterAndRaceCreation() public {
        // grant admin role
        vm.prank(owner);
        bls.setAdminRights(user1, true);

        // validate the admin role
        assertTrue(bls.userHasAdminAccess(user1));

        // add the race finally :)
        vm.startPrank(owner);
        bls.addRace(
            0,
            1,
            2,
            0,
            screens,
            abi.encode(points), // for bullrun init
            abi.encode(questions) // for underdog init
        );

        // register
        bls.register(0, user1); // 0 - is the id of the first race
        vm.stopPrank();

        // verify the user registration result
        assertTrue(bls.isPlayerRegistered(0, user1));
    }

    function test_Revert_When_RefundingOnNotFinishedRace() public {
        // grant admin role
        vm.prank(owner);
        bls.setAdminRights(user1, true);

        // add the race finally :)
        vm.startPrank(user1);
        bls.addRace(
            0,
            1,
            2,
            0,
            screens,
            abi.encode(points), // for bullrun init
            abi.encode(questions) // for underdog init
        );
        vm.stopPrank();

        // register
        vm.startPrank(owner);
        bls.register(0, user1); // 0 - is the id of the first race

        vm.expectRevert();
        bls.refundWinningBalance(0); // 0 - is the id of the first race

        vm.stopPrank();
    }

    function test_Distribute() public {
        uint256[4] memory entryPrices = [
            uint256(10000000),
            uint256(5000000),
            uint256(2000000),
            uint256(1000000)
        ]; // with 6 decimals

        for (uint256 e = 0; e < entryPrices.length; e++) {
            uint256 entryPrice = entryPrices[e];

            vm.startPrank(owner);

            bls.addRace(
                entryPrice,
                1,
                7,
                0,
                screens,
                abi.encode(points),
                abi.encode(questions)
            );

            uint256 raceId = e;

            bls.register(raceId, user1);
            bls.register(raceId, user2);
            bls.register(raceId, user3);
            bls.register(raceId, user4);
            bls.register(raceId, user5);
            bls.register(raceId, user6);
            bls.register(raceId, user7);

            vm.stopPrank();
        }

        vm.warp(block.timestamp + 1 hours);

        for (uint256 e = 0; e < entryPrices.length; e++) {
            uint256 entryPrice = entryPrices[e];

            uint256 raceId = e;

            // tests performs with 7 registered users
            // Multipliers for 7 players: [514, 214, 157, 0, 0, 0, 0], houseCut: 114
            // totalPool = entryPrice * 7
            // Integer division causes rounding losses
            if (entryPrice == 10000000) {
                // (70000000 * 514) / 1000 = 35980000
                assertEq(bls.possibleRefundingAmount(raceId, user1), 35980000);
                // (70000000 * 214) / 1000 = 14980000
                assertEq(bls.possibleRefundingAmount(raceId, user2), 14980000);
                // (70000000 * 157) / 1000 = 10990000
                assertEq(bls.possibleRefundingAmount(raceId, user3), 10990000);
                assertEq(bls.possibleRefundingAmount(raceId, user4), 0);
            }

            if (entryPrice == 5000000) {
                // (35000000 * 514) / 1000 = 17990000
                assertEq(bls.possibleRefundingAmount(raceId, user1), 17990000);
                // (35000000 * 214) / 1000 = 7490000
                assertEq(bls.possibleRefundingAmount(raceId, user2), 7490000);
                // (35000000 * 157) / 1000 = 5495000
                assertEq(bls.possibleRefundingAmount(raceId, user3), 5495000);
                assertEq(bls.possibleRefundingAmount(raceId, user4), 0);
            }

            if (entryPrice == 2000000) {
                // (14000000 * 514) / 1000 = 7196000
                assertEq(bls.possibleRefundingAmount(raceId, user1), 7196000);
                // (14000000 * 214) / 1000 = 2996000
                assertEq(bls.possibleRefundingAmount(raceId, user2), 2996000);
                // (14000000 * 157) / 1000 = 2198000
                assertEq(bls.possibleRefundingAmount(raceId, user3), 2198000);
                assertEq(bls.possibleRefundingAmount(raceId, user4), 0);
            }

            if (entryPrice == 1000000) {
                // (7000000 * 514) / 1000 = 3598000
                assertEq(bls.possibleRefundingAmount(raceId, user1), 3598000);
                // (7000000 * 214) / 1000 = 1498000
                assertEq(bls.possibleRefundingAmount(raceId, user2), 1498000);
                // (7000000 * 157) / 1000 = 1099000
                assertEq(bls.possibleRefundingAmount(raceId, user3), 1099000);
                assertEq(bls.possibleRefundingAmount(raceId, user4), 0);
            }
        }
    }
}
