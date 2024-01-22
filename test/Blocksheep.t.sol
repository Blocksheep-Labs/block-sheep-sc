// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Blacksheep} from "src/Blacksheep.sol";

contract BlackSheepTest is Test {
    Blacksheep public blacksheep;
    address owner = address(1);

    function setUp() public {
        vm.startPrank(owner);
        blacksheep = new Blacksheep();
        vm.stopPrank();
    }

    function test_contractOwner() public {
        assertEq(blacksheep.owner(), owner);
    }
}

contract AddQuestionsTest is BlackSheepTest {
    function test_addQuestions() public {
        assertEq(blacksheep.TOTAL_NofQUESTIONS(), 1);
        string memory questionText = "Question 1";
        string memory answers = "Answer 1";
        uint256 numOfAnswers = 2;
        uint256 limitOfAnswers = 3;
        uint256 intitialStartDate = block.timestamp + 1 hours;
        uint256 numOfDays_Submit = 3;
        uint256 numOfDays_Commit = 2;
        uint256 numOfDays_BeforeResult = 1;
        uint256 numOfDays_RepeatAfterResult = 4;
        uint256 repeatCount = 5;
        uint256 cost = 1;
        vm.startPrank(owner);
        blacksheep.addQuestions(
            questionText,
            answers,
            numOfAnswers,
            limitOfAnswers,
            intitialStartDate,
            numOfDays_Submit,
            numOfDays_Commit,
            numOfDays_BeforeResult,
            numOfDays_RepeatAfterResult,
            repeatCount,
            cost
        );
        vm.stopPrank();
        assertEq(blacksheep.TOTAL_NofQUESTIONS(), 2);
        Blacksheep.Question memory question = blacksheep.getQuestion(1);
        assertEq(
            abi.encode(question),
            abi.encode(
                Blacksheep.Question({
                    QuestionText: questionText,
                    Answers: answers,
                    AnswerCount: numOfAnswers,
                    NofAnswersLimit: limitOfAnswers,
                    IntitialStartDate: intitialStartDate,
                    NofDays_Submit: numOfDays_Submit,
                    NofDays_Commit: numOfDays_Commit,
                    NofDays_BeforeResult: numOfDays_BeforeResult,
                    NofDays_RepeatAfterResult: numOfDays_RepeatAfterResult,
                    RepeatCount: repeatCount,
                    Cost: cost,
                    repeatFlag: 1
                })
            )
        );
    }
}
