pragma solidity ^0.8.20;

import {BlockSheep} from "src/BlockSheep.sol";
import {BlockSheepTest} from "test/contracts/BlockSheep.t.sol";

contract AddRaceTest is BlockSheepTest {
    function setUp() public override {
        super.setUp();
        vm.startPrank(owner);
        addGame();
        addQuestions();
        vm.stopPrank();
    }

    function test_AddRaceAsOwner() public {
        vm.startPrank(owner);
        addRaceInternal();
        vm.stopPrank();
    }

    function test_RevertWhen_CallerIsNotOwner() public {
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                address(2)
            )
        );
        vm.startPrank(address(2));
        addRaceInternal();
        vm.stopPrank();
    }
}
