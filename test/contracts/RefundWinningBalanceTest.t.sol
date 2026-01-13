// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {BlockSheep} from "../../src/BlockSheep.sol";

// game contracts
import {GameBullrun} from "../../src/GameBullrun.sol";
import {GameRabbitHole} from "../../src/GameRabbitHole.sol";
import {GameUnderdog} from "../../src/GameUnderdog.sol";

contract RefundWinningBalanceTest is Test {
    BlockSheep bls;
    BlockSheep.RaceInfo raceInfo;

    address owner = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);
    address user3 = address(0x4);
    address user4 = address(0x5);
    address user5 = address(0x6);
    address user6 = address(0x7);
    address user7 = address(0x8);
    address user8 = address(0x9);
    address user9 = address(0x10);

    string[] screens;
    int256[3][3] points;
    GameUnderdog.QuestionInfo[] questions;

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
        screens[0] = "UNDERDOG";

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

    function testRefundWinningBalance_3Players() public {
        vm.startPrank(owner);

        // Create race with entry price 1 USDC
        bls.addRace(
            1000000, // 1 USDC with 6 decimals
            1, // hours before finish
            3, // numOfPlayersRequired
            0, // storyKey
            screens,
            abi.encode(points),
            abi.encode(questions)
        );

        uint256 raceId = 0;

        // Register 3 players
        bls.register(raceId, user1);
        bls.register(raceId, user2);
        bls.register(raceId, user3);

        vm.stopPrank();

        // Submit answers to create score differences
        vm.prank(user1);
        bls.makeMove("UNDERDOG", raceId, abi.encode(uint8(0), uint8(0), user1)); // user1 answers question 0, answer 0

        vm.prank(user2);
        bls.makeMove("UNDERDOG", raceId, abi.encode(uint8(0), uint8(1), user2)); // user2 answers question 0, answer 1

        // user3 doesn't answer (lower score)

        // Warp time to finish the race
        vm.warp(block.timestamp + 2 hours);

        // Check scores
        int256 score1 = bls.getScoreAtRaceOfUser(raceId, user1);
        int256 score2 = bls.getScoreAtRaceOfUser(raceId, user2);
        int256 score3 = bls.getScoreAtRaceOfUser(raceId, user3);

        console.log("User1 score:", uint256(score1));
        console.log("User2 score:", uint256(score2));
        console.log("User3 score:", uint256(score3));

        // Total pool: 3 USDC
        // 1st place: 3 * 667 / 1000 = 2.001 ≈ 2 USDC (66.7%)
        // 2nd place: 0 USDC
        // 3rd place: 0 USDC
        // House: 3 * 333 / 1000 = 0.999 ≈ 0 USDC (33.3%)

        // Refund for each user
        vm.prank(user1);
        bls.refundWinningBalance(raceId);

        vm.prank(user2);
        bls.refundWinningBalance(raceId);

        vm.prank(user3);
        bls.refundWinningBalance(raceId);

        // Check withdrawals
        uint256 withdrawal1 = bls.raceWithdrawals(raceId, user1);
        uint256 withdrawal2 = bls.raceWithdrawals(raceId, user2);
        uint256 withdrawal3 = bls.raceWithdrawals(raceId, user3);

        console.log("User1 withdrawal:", withdrawal1);
        console.log("User2 withdrawal:", withdrawal2);
        console.log("User3 withdrawal:", withdrawal3);
        console.log("House collected:", bls.house());

        // Verify withdrawals (3 players, entryPrice=1000000)
        // Total pool: 3000000 (3 USDC)
        // 1st place: 3000000 * 667 / 1000 = 2001000 (2.001 USDC)
        // House: 3000000 * 333 / 1000 = 999000 (0.999 USDC)
        assertEq(withdrawal1, 2001000); // 1st place: 2.001 USDC
        assertEq(withdrawal2, 0); // 2nd place: 0
        assertEq(withdrawal3, 0); // 3rd place: 0
        assertEq(bls.house(), 999000); // House: 0.999 USDC

        // Verify refunded status
        BlockSheep.RaceInfo memory raceInfo1 = bls.getRace(raceId, user1);
        BlockSheep.RaceInfo memory raceInfo2 = bls.getRace(raceId, user2);
        BlockSheep.RaceInfo memory raceInfo3 = bls.getRace(raceId, user3);

        assertTrue(raceInfo1.refunded);
        assertTrue(raceInfo2.refunded);
        assertTrue(raceInfo3.refunded);
    }

    function testRefundWinningBalance_4Players() public {
        vm.startPrank(owner);

        bls.addRace(
            1000000, // 1 USDC with 6 decimals
            1,
            4,
            0,
            screens,
            abi.encode(points),
            abi.encode(questions)
        );

        uint256 raceId = 0;

        bls.register(raceId, user1);
        bls.register(raceId, user2);
        bls.register(raceId, user3);
        bls.register(raceId, user4);

        vm.stopPrank();

        // Simulate different scores
        vm.prank(user1);
        bls.makeMove("UNDERDOG", raceId, abi.encode(uint8(0), uint8(0), user1));

        vm.prank(user2);
        bls.makeMove("UNDERDOG", raceId, abi.encode(uint8(0), uint8(1), user2));

        vm.warp(block.timestamp + 2 hours);

        // Refund
        vm.prank(user1);
        bls.refundWinningBalance(raceId);

        vm.prank(user2);
        bls.refundWinningBalance(raceId);

        vm.prank(user3);
        bls.refundWinningBalance(raceId);

        vm.prank(user4);
        bls.refundWinningBalance(raceId);

        // Total pool: 4 USDC (4000000)
        // 1st place: 4000000 * 500 / 1000 = 2000000 (2 USDC) (50%)
        // 2nd place: 4000000 * 375 / 1000 = 1500000 (1.5 USDC) (37.5%)
        // House: 4000000 * 125 / 1000 = 500000 (0.5 USDC) (12.5%)

        uint256 withdrawal1 = bls.raceWithdrawals(raceId, user1);
        uint256 withdrawal2 = bls.raceWithdrawals(raceId, user2);
        uint256 withdrawal3 = bls.raceWithdrawals(raceId, user3);
        uint256 withdrawal4 = bls.raceWithdrawals(raceId, user4);

        console.log("4 players - User1 withdrawal:", withdrawal1);
        console.log("4 players - User2 withdrawal:", withdrawal2);
        console.log("4 players - User3 withdrawal:", withdrawal3);
        console.log("4 players - User4 withdrawal:", withdrawal4);
        console.log("4 players - House:", bls.house());

        assertEq(withdrawal1, 2000000); // 1st place: 2 USDC
        assertEq(withdrawal2, 1500000); // 2nd place: 1.5 USDC
        assertEq(withdrawal3, 0); // 3rd place
        assertEq(withdrawal4, 0); // 4th place
        assertEq(bls.house(), 500000); // House: 0.5 USDC
    }

    function testRefundWinningBalance_9Players() public {
        vm.startPrank(owner);

        bls.addRace(
            1000000, // 1 USDC with 6 decimals
            1,
            9,
            0,
            screens,
            abi.encode(points),
            abi.encode(questions)
        );

        uint256 raceId = 0;

        bls.register(raceId, user1);
        bls.register(raceId, user2);
        bls.register(raceId, user3);
        bls.register(raceId, user4);
        bls.register(raceId, user5);
        bls.register(raceId, user6);
        bls.register(raceId, user7);
        bls.register(raceId, user8);
        bls.register(raceId, user9);

        vm.stopPrank();

        // Create score differences
        vm.prank(user1);
        bls.makeMove("UNDERDOG", raceId, abi.encode(uint8(0), uint8(0), user1));

        vm.prank(user2);
        bls.makeMove("UNDERDOG", raceId, abi.encode(uint8(0), uint8(1), user2));

        vm.warp(block.timestamp + 2 hours);

        // Refund all users
        vm.prank(user1);
        bls.refundWinningBalance(raceId);

        vm.prank(user2);
        bls.refundWinningBalance(raceId);

        vm.prank(user3);
        bls.refundWinningBalance(raceId);

        vm.prank(user4);
        bls.refundWinningBalance(raceId);

        vm.prank(user5);
        bls.refundWinningBalance(raceId);

        vm.prank(user6);
        bls.refundWinningBalance(raceId);

        vm.prank(user7);
        bls.refundWinningBalance(raceId);

        vm.prank(user8);
        bls.refundWinningBalance(raceId);

        vm.prank(user9);
        bls.refundWinningBalance(raceId);

        // Total pool: 9 USDC
        // 1st: 9 * 456 / 1000 = 4.104 ≈ 4 USDC
        // 2nd: 9 * 200 / 1000 = 1.8 ≈ 1 USDC
        // 3rd: 9 * 122 / 1000 = 1.098 ≈ 1 USDC
        // 4th: 9 * 111 / 1000 = 0.999 ≈ 0 USDC
        // House: 9 * 111 / 1000 = 0.999 ≈ 0 USDC

        uint256 withdrawal1 = bls.raceWithdrawals(raceId, user1);
        uint256 withdrawal2 = bls.raceWithdrawals(raceId, user2);
        uint256 withdrawal3 = bls.raceWithdrawals(raceId, user3);
        uint256 withdrawal4 = bls.raceWithdrawals(raceId, user4);

        console.log("9 players - User1 withdrawal:", withdrawal1);
        console.log("9 players - User2 withdrawal:", withdrawal2);
        console.log("9 players - User3 withdrawal:", withdrawal3);
        console.log("9 players - User4 withdrawal:", withdrawal4);
        console.log("9 players - House:", bls.house());

        // Total pool: 9000000 (9 USDC)
        // 1st: 9000000 * 456 / 1000 = 4104000 (4.104 USDC)
        // 2nd: 9000000 * 200 / 1000 = 1800000 (1.8 USDC)
        // 3rd: 9000000 * 122 / 1000 = 1098000 (1.098 USDC)
        // 4th: 9000000 * 111 / 1000 = 999000 (0.999 USDC)
        // House: 9000000 * 111 / 1000 = 999000 (0.999 USDC)
        assertEq(withdrawal1, 4104000); // 1st: 4.104 USDC
        assertEq(withdrawal2, 1800000); // 2nd: 1.8 USDC
        assertEq(withdrawal3, 1098000); // 3rd: 1.098 USDC
        assertEq(withdrawal4, 999000); // 4th: 0.999 USDC
        assertEq(bls.house(), 999000); // House: 0.999 USDC
    }

    function testRefundWinningBalance_RevertAlreadyRefunded() public {
        vm.startPrank(owner);

        bls.addRace(
            1000000,
            1,
            3,
            0,
            screens,
            abi.encode(points),
            abi.encode(questions)
        );

        uint256 raceId = 0;

        bls.register(raceId, user1);
        bls.register(raceId, user2);
        bls.register(raceId, user3);

        vm.stopPrank();

        vm.warp(block.timestamp + 2 hours);

        // First refund should succeed
        vm.prank(user1);
        bls.refundWinningBalance(raceId);

        // Second refund should fail
        vm.prank(user1);
        vm.expectRevert("Already refunded");
        bls.refundWinningBalance(raceId);
    }

    function testRefundWinningBalance_RevertNotRegistered() public {
        vm.prank(owner);
        bls.addRace(
            1000000,
            1,
            3,
            0,
            screens,
            abi.encode(points),
            abi.encode(questions)
        );

        uint256 raceId = 0;

        vm.warp(block.timestamp + 2 hours);

        // Try to refund without registration
        vm.prank(user1);
        vm.expectRevert("Not registered");
        bls.refundWinningBalance(raceId);
    }

    function testRefundWinningBalance_HouseCalculatedOnce() public {
        vm.startPrank(owner);

        bls.addRace(
            1000000,
            1,
            4,
            0,
            screens,
            abi.encode(points),
            abi.encode(questions)
        );

        uint256 raceId = 0;

        bls.register(raceId, user1);
        bls.register(raceId, user2);
        bls.register(raceId, user3);
        bls.register(raceId, user4);

        vm.stopPrank();

        vm.warp(block.timestamp + 2 hours);

        // First refund calculates house
        vm.prank(user1);
        bls.refundWinningBalance(raceId);

        uint256 houseAfterFirst = bls.house();

        // Second refund should not add to house again
        vm.prank(user2);
        bls.refundWinningBalance(raceId);

        uint256 houseAfterSecond = bls.house();

        assertEq(
            houseAfterFirst,
            houseAfterSecond,
            "House should only be calculated once"
        );
    }

    function testPossibleRefundingAmount() public {
        vm.startPrank(owner);

        bls.addRace(
            1000000,
            1,
            4,
            0,
            screens,
            abi.encode(points),
            abi.encode(questions)
        );

        uint256 raceId = 0;

        bls.register(raceId, user1);
        bls.register(raceId, user2);
        bls.register(raceId, user3);
        bls.register(raceId, user4);

        vm.stopPrank();

        // Before race ends, refund amount should be 0
        uint256 refundBefore = bls.possibleRefundingAmount(raceId, user1);
        assertEq(refundBefore, 0);

        vm.warp(block.timestamp + 2 hours);

        // After race ends, check refund amounts
        uint256 refund1 = bls.possibleRefundingAmount(raceId, user1);
        uint256 refund2 = bls.possibleRefundingAmount(raceId, user2);

        console.log("Possible refund user1:", refund1);
        console.log("Possible refund user2:", refund2);

        // Should match actual withdrawals
        vm.prank(user1);
        bls.refundWinningBalance(raceId);

        uint256 actualWithdrawal1 = bls.raceWithdrawals(raceId, user1);
        assertEq(refund1, actualWithdrawal1);
    }
}
