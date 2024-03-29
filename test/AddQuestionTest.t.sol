pragma solidity ^0.8.20;

import {BlockSheep} from "src/BlockSheep.sol";
import {BlockSheepTest} from "test/BlockSheep.t.sol";

contract AddQuestionTest is BlockSheepTest {
    string private question = "What fruit do you like";

    function test_AddQuestionAsOwner() public {
        vm.startPrank(owner);
        blockSheep.addQuestion(
            BlockSheep.QuestionInfo({content: question, answers: _getAnswers()})
        );
        vm.stopPrank();

        BlockSheep.QuestionInfo memory questionInfo = blockSheep.getQuestions(
            0
        );
        assertEq(questionInfo.content, question);
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
