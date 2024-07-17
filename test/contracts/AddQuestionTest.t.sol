pragma solidity ^0.8.20;

import {BlockSheep} from "src/BlockSheep.sol";
import {BlockSheepTest} from "test/contracts/BlockSheep.t.sol";

contract AddQuestionTest is BlockSheepTest {
    string private question = "What fruit do you like";

    function test_AddQuestionAsOwner() public {
        vm.startPrank(owner);
        blockSheep.addQuestion(
            BlockSheep.QuestionInfo({content: question, answers: _getAnswers()})
        );
        vm.stopPrank();

        string memory questionInfo = blockSheep.questions(
            0
        );
        assertEq(questionInfo, question);
    }

    function test_RevertWhen_CallerIsNotOwner() public {
        vm.expectRevert(
            abi.encodeWithSignature(
                "OwnableUnauthorizedAccount(address)",
                address(2)
            )
        );
        vm.prank(address(2));
        blockSheep.addQuestion(
            BlockSheep.QuestionInfo({content: question, answers: _getAnswers()})
        );
    }

    function _getAnswers() private pure returns (string[] memory answers) {
        answers = new string[](2);
        answers[0] = "apple";
        answers[1] = "pear";
    }
}
