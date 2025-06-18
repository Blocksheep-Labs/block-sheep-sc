// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

import { BlockSheep } from "../../src/BlockSheep.sol";
import { MockUSDC } from "../../src/MockUSDC.sol";

// game contracts
import { GameBullrun } from "../../src/GameBullrun.sol";
import { GameRabbitHole } from"../../src/GameRabbitHole.sol";
import { GameUnderdog } from "../../src/GameUnderdog.sol";


contract BlockSheepTest is Test {
    BlockSheep bls;

    address owner = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);

    uint8 decimals = 1;


    string[] screens; // screens sequence
    int256[3][3] points; // for bullrun
    GameUnderdog.QuestionInfo[] questions; // for underdog;

    function setUp() public {
        vm.prank(owner);

        bls = new BlockSheep(
            owner
        );



        // register games
        GameUnderdog   underdog   = new GameUnderdog();
        GameRabbitHole rabbitHole = new GameRabbitHole();
        GameBullrun    bullrun    = new GameBullrun();

        bls.registerContract("UNDERDOG",   address(underdog));
        bls.registerContract("RABBITHOLE", address(rabbitHole));
        bls.registerContract("BULLRUN",    address(bullrun));


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

    function testDeposit() public {
        uint256 amountToDeposit = 10 * 10 ** decimals;

        vm.startPrank(owner);
        bls.deposit(amountToDeposit, user1);
        vm.stopPrank();

        assertEq(bls.balances(user1), amountToDeposit);
    }

    function testWithdraw() public {
        uint256 amount = 10 * 10 ** decimals;

        vm.startPrank(owner);
        bls.deposit(amount, user1);
        vm.stopPrank();

        vm.startPrank(user1);
        bls.withdraw(amount);
        vm.stopPrank();

        assertEq(bls.balances(user1), 0);
    }


    function testRegisterAndRaceCreation() public {
        uint256 amount = 10 * 10 ** decimals;

        // deposit money
        vm.startPrank(owner);
        bls.deposit(amount, user1);
        vm.stopPrank();

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


    function testInsufficientBalanceOnWithdraw() public {
        vm.startPrank(user1);

        // user has no balance, expecting a revert
        vm.expectRevert();

        bls.withdraw(10 * 10 ** decimals);

        vm.stopPrank();
    }


    function testSuccesfulRefund() public {
        uint256 amount = 10 * 10 ** decimals;

        // deposit money
        vm.startPrank(owner);
        bls.deposit(amount, user1);

        // grant admin role
        bls.setAdminRights(user1, true);

        // add the race finally :)
        bls.addRace(
            0,
            1, 
            2, 
            0,
            screens, 
            abi.encode(points), // for bullrun init
            abi.encode(questions) // for underdog init
        );

        // register user
        bls.register(0, user1); // 0 - is the id of the first race

        console.log(block.timestamp);
        vm.warp(block.timestamp + 2 hours);
        console.log(block.timestamp);

        vm.stopPrank();

        vm.startPrank(user1);
        bls.refundWinningBalance(0); // 0 - is the id of the first race
        vm.stopPrank();

        assertEq(bls.balances(user1), amount);
    }


    function test_Revert_When_RefundingOnNotFinishedRace() public {
        uint256 amount = 10 * 10 ** decimals;

        // deposit money
        vm.startPrank(owner);
        bls.deposit(amount, user1);
        vm.stopPrank();

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
}