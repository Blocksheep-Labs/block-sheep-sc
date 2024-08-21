pragma solidity ^0.8.20;

import {BlockSheep} from "src/BlockSheep.sol";
import {BlockSheepTest} from "test/contracts/BlockSheep.t.sol";

contract DepositWithdrawTest is BlockSheepTest {
    function test_DepositIncreaseBalance() public {
        uint256 amount = 10e6;

        vm.deal(playerOne, amount); // Give playerOne enough Ether for the deposit

        vm.startPrank(playerOne);
        blockSheep.deposit{value: amount}(); // Send Ether with the deposit transaction
        vm.stopPrank();

        uint256 tokenPrice = blockSheep.tokenPrice(); // Retrieve the token price from the contract
        uint256 expectedBalance = amount / tokenPrice; // Calculate the expected balance
        assertEq(blockSheep.balances(playerOne), expectedBalance);
    }

    function test_withdrawDecreaseBalance() public {
        uint256 amount = 10e6;

        vm.deal(playerOne, amount); // Give playerOne enough Ether for the deposit

        vm.startPrank(playerOne);
        blockSheep.deposit{value: amount}(); // Deposit Ether

        uint256 tokenPrice = blockSheep.tokenPrice(); // Retrieve the token price from the contract
        uint256 expectedBalance = amount / tokenPrice; // Calculate the expected balance
        
        assertEq(blockSheep.balances(playerOne), expectedBalance);
        blockSheep.withdraw(expectedBalance);
        vm.stopPrank();

        assertEq(blockSheep.balances(playerOne), 0);
    }
}
