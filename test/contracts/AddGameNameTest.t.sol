pragma solidity ^0.8.20;

import {BlockSheep} from "src/BlockSheep.sol";
import {BlockSheepTest} from "test/BlockSheep.t.sol";

contract AddGameNameTest is BlockSheepTest {
    string private gameName = "quiz";

    function test_AddGameNameAsOwner() public {
        vm.startPrank(owner);
        blockSheep.addGameName(gameName);
        vm.stopPrank();

        assertEq(blockSheep.getGameNames(0), gameName);
    }

    function test_RevertWhen_CallerIsNotOwner() public {
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                address(2)
            )
        );
        vm.prank(address(2));
        blockSheep.addGameName(gameName);
    }
}
