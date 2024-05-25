pragma solidity ^0.8.20;

import {BlockSheep} from "src/BlockSheep.sol";
import {BlockSheepTest} from "test/BlockSheep.t.sol";

contract DepositWithdrawTest is BlockSheepTest {
    function test_DepositIncreaseBalance() public {
        uint256 amount = 10e6;
        vm.startPrank(playerOne);
        usdc.approve(address(blockSheep), amount);
        blockSheep.deposit(amount);
        vm.stopPrank();
        assertEq(blockSheep.balances(playerOne), amount);
    }

    function test_withdrawDecreaseBalance() public {
        uint256 amount = 10e6;
        vm.startPrank(playerOne);
        usdc.approve(address(blockSheep), amount);
        blockSheep.deposit(amount);

        assertEq(blockSheep.balances(playerOne), amount);

        blockSheep.withdraw(amount);
        vm.stopPrank();
        assertEq(blockSheep.balances(playerOne), 0);
    }
}
