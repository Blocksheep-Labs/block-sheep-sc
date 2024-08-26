pragma solidity ^0.8.20;

import {BlockSheep} from "src/BlockSheep.sol";
import {BlockSheepTest} from "test/contracts/BlockSheep.t.sol";

contract RegisterTest is BlockSheepTest {
    function setUp() public override {
        super.setUp();
        vm.startPrank(owner);
        addGame();
        addQuestions();
        addRaceInternal();
        vm.stopPrank();
    }

    function test_Register() public {
        vm.startPrank(playerOne);
        registerInternal(playerOne, 0);
        vm.stopPrank();
    }

    function test_RevertIf_RaceIsFull() public {
        registerInternal(playerOne, 0);
        registerInternal(playerTwo, 0);
        registerInternal(playerThree, 0);
        // vm.expectRevert(BlockSheep.RaceIsFull.selector);
        // vm.expectRevert();
        uint256 amount = 30e6;
        vm.startPrank(playerFour);
        usdc.approve(address(blockSheep), amount);
        blockSheep.deposit(amount);
        vm.expectRevert(BlockSheep.RaceIsFull.selector);
        blockSheep.register(0);
        vm.stopPrank();
    }
}
