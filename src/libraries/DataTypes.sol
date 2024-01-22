// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

library DataTypes {
    enum Status {
        SUBMITTED,
        COMMITTED,
        COMMIT_FAILED,
        RESULT_DECLARED
    } // SUBMITTED, COMMITTED, failedcommit, RESULT_DECLARED

    struct Question {
        string questionText; // question
        string answers; // "lorem ipsum, lorem ipsum"
        uint256 numOfAnswers; // number of options avaliable
        uint256 numOfAnswersLimit; // number of user can attemp question
        uint256 initialStartDate; // First time start date 1528191889
        uint256 numOfDaysSubmit; // 6 i.e.x sec
        uint256 numOfDaysCommit; // 2
        uint256 numOfDaysBeforeResult; // 1
        uint256 numOfDaysRepeatAfterResult; // 20
        uint256 repeatLimit; // number of time question repeat
        uint256 cost; // cost of question in kwei
        uint256 repeatCnt;
    }

    struct QuestionCycle {
        uint256 cycleId; // cycleId is cycle ID
        uint256 questionId; // questionId is question ID
        uint256 currentStartDate; //Current new start date, First time it is same as intitialStartDate, updated by result-declaration
        uint256 currentSubmitEndDate; // Updated when question first triggered
        uint256 currentCommitDateStart;
        uint256 currentCommitDateEnd;
        uint256 currentResultDate;
        uint256 nextStartDate;
        address[] usersAnswered; // array of UIDs who attempted the Que {UIDs... }
        address[] usersCommitted; // array of UIDs who COMMITTED the Que {UIDs... }
        string[] committedAnswerTexts; //array of COMMITTED answer texts
        uint256 numOfAnswersGiven;
        uint256 numOfAnswersLimit;
        bool rewardCalculated;
        string winningAnswer;
    }

    struct UserAnswer {
        Status status;
        address sender;
        uint256 submittedDate;
        uint256 committedDate;
        uint256 resultDate;
        string answer;
    }

    // Per User answer data
    struct UserAnswers {
        Status status;
        uint256 submittedCycleId; // cycleId SUBMITTED by one User
        uint256 commitedCycleId; // cycleId COMMITTED by one User
        uint256 submittedDate;
        uint256 committedDate;
        uint256 resultDate;
        string answer;
        bool SUBMITTED;
        bool COMMITTED;
    }
}
