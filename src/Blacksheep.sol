pragma solidity ^0.8.20;
import "./strings.sol";

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Address} from "../lib/openzeppelin-contracts/contracts/utils/Address.sol";

import {DataTypes} from "./libraries/DataTypes.sol";

/**
 * @title Blacksheep
 * @dev The Blacksheep contract has functionality for admin to add multiple questions and answer and other options like intitial_start_date, no_of_days_submit, no_of_days_commit, no_of_days_before_result, no_of_days_result_active in contract. user can vote for questions and win ether.
 */
contract Blacksheep is Ownable {
    using Address for address;
    using strings for *;

    event logTransfer(address from, address to, uint256 amount);
    event logQuestionInfo(string info, uint256 q_id);
    event logQuestionCycle(string info, uint256 q_id);
    event logQuestionCycleCommit(string info, uint256[] q_id);
    event logBoolEvent(string info, bool _condition);

    uint256 public totalNumOfQuestions = 1; // total count of questions updated each time admin updates questions db.
    uint256 public currentCycleId = 1; // total count of questions cycle each time result is calculated.
    uint256 public totalWithdrawableAmount = 0; // total count of questions cycle each time result is calculated.

    mapping(address => uint256) public userBalance;

    // questions: array of Question, where questionId is assumed to be an integer....0,1,2....
    // Each Question is added to "questions" from the Admin be calling a writeable SC method addQuestions(QueStr as string)
    mapping(uint256 => DataTypes.Question) public questions;

    // The addQuestions method not only adds each question to the "questions" array, but also adds the same Question to the
    // "currentQuestions" array with the appropriate dates.
    // So every question will be in the currentQuestions array with the current or upcoming dates setup and will be used
    // to maintain UIDs of users answering the question.
    // uint256 is questionId of questions
    mapping(uint256 => DataTypes.QuestionCycle) public currentQuestions;

    // uint256 is questionId of questions
    mapping(uint256 => DataTypes.UserAnswer) public QIDAnswers; // Question wise Answers (persumably for one user)

    mapping(address => DataTypes.UserAnswers[]) public CURRENT_UserAnswers; //All questions answered by each user

    constructor() Ownable(msg.sender) {}

    function addQuestions(
        string memory _QuestionText,
        string memory _Answers,
        uint256 _AnswerCount,
        uint256 _NofAnswersLimit,
        uint256 _IntitialStartDate,
        uint256 _NofDays_Submit,
        uint256 _NofDays_Commit,
        uint256 _NofDays_BeforeResult,
        uint256 _NofDays_RepeatAfterResult,
        uint256 _RepeatCount,
        uint256 _Cost
    ) public onlyOwner {
        //require(bytes(_QuestionText).length > 0 && bytes(_Answers).length > 0,  "Values cannot be blank");
        DataTypes.Question storage question = questions[totalNumOfQuestions];
        question.questionText = _QuestionText;
        question.answers = _Answers;
        question.numOfAnswers = _AnswerCount;
        question.numOfAnswersLimit = _NofAnswersLimit;
        question.initialStartDate = _IntitialStartDate;
        question.numOfDaysSubmit = _NofDays_Submit;
        question.numOfDaysCommit = _NofDays_Commit;
        question.numOfDaysBeforeResult = _NofDays_BeforeResult;
        question.numOfDaysRepeatAfterResult = _NofDays_RepeatAfterResult;
        question.repeatLimit = _RepeatCount;
        question.cost = _Cost;
        question.repeatCnt = 1;

        _addQuestionCycle(currentCycleId, totalNumOfQuestions);
    }

    function _addQuestionCycle(uint256 _cid, uint256 _qid) internal {
        require(_cid != 0 && _qid != 0, "Values cannot be blank");
        DataTypes.QuestionCycle memory cycle = currentQuestions[_cid];
        DataTypes.Question memory question = questions[_qid];
        cycle.cycleId = _cid;
        cycle.questionId = _qid;
        cycle.currentStartDate = question.initialStartDate;
        cycle.currentSubmitEndDate =
            question.initialStartDate +
            question.numOfDaysSubmit;
        cycle.currentCommitDateStart = cycle.currentSubmitEndDate;
        cycle.currentCommitDateEnd =
            cycle.currentCommitDateStart +
            question.numOfDaysCommit;
        cycle.currentResultDate =
            cycle.currentCommitDateEnd +
            question.numOfDaysBeforeResult;
        cycle.nextStartDate =
            cycle.currentCommitDateEnd +
            question.numOfDaysBeforeResult +
            question.numOfDaysRepeatAfterResult;

        cycle.numOfAnswersLimit = question.numOfAnswersLimit;

        totalNumOfQuestions++;
        currentCycleId++;
    }

    function getQuestion(
        uint256 questionId
    ) public view returns (DataTypes.Question memory) {
        return questions[questionId];
    }

    function getCountOfActiveQuestions(
        address user
    ) public view returns (uint256[] memory) {
        uint256[] memory active_question = new uint256[](
            _getActiveQuestionCount(user)
        );
        uint256 counter = 0;
        for (uint256 i = 1; i < currentCycleId; i++) {
            if (
                _checkIfUserAlreadyAnswered(user, i) &&
                currentQuestions[i].currentStartDate <= block.timestamp &&
                currentQuestions[i].currentSubmitEndDate >= block.timestamp &&
                currentQuestions[i].usersAnswered.length <
                currentQuestions[i].numOfAnswersLimit
            ) {
                active_question[counter] = currentQuestions[i].cycleId;
                counter++;
            }
        }
        return active_question;
    }

    function _getActiveQuestionCount(
        address user
    ) internal view returns (uint256) {
        uint256 count = 1;
        for (uint256 i = 1; i < currentCycleId; i++) {
            if (
                _checkIfUserAlreadyAnswered(user, i) &&
                currentQuestions[i].currentStartDate <= block.timestamp &&
                currentQuestions[i].currentSubmitEndDate >= block.timestamp &&
                currentQuestions[i].usersAnswered.length <
                currentQuestions[i].numOfAnswersLimit
            ) {
                count++;
            }
        }
        return count;
    }

    function getQuestionForSubmit(
        uint256 _cid
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            string memory,
            string memory,
            uint256,
            uint256
        )
    {
        if (
            _checkIfUserAlreadyAnswered(msg.sender, _cid) &&
            currentQuestions[_cid].currentStartDate <= block.timestamp &&
            currentQuestions[_cid].currentSubmitEndDate >= block.timestamp &&
            currentQuestions[_cid].usersAnswered.length <
            currentQuestions[_cid].numOfAnswersLimit
        ) {
            uint256 _index = currentQuestions[_cid].questionId;
            return (
                currentQuestions[_cid].cycleId,
                currentQuestions[_cid].questionId,
                currentQuestions[_cid].currentSubmitEndDate,
                currentQuestions[_cid].currentCommitDateEnd,
                questions[_index].questionText,
                questions[_index].answers,
                questions[_index].numOfAnswers,
                questions[_index].cost
            );
        }
    }

    function _checkIfUserAlreadyAnswered(
        address user,
        uint256 _cid
    ) internal view returns (bool) {
        for (
            uint256 i = 0;
            i < currentQuestions[_cid].usersAnswered.length;
            i++
        ) {
            if (currentQuestions[_cid].usersAnswered[i] == user) {
                return false;
            }
        }
        return true;
    }

    function submitAnswer(
        uint256 _cid,
        uint256 _current_qid,
        string memory _encryptedAns
    ) public payable returns (bool success) {
        require(
            msg.value == questions[_current_qid].cost,
            "Provide required amount to submit answer."
        );
        require(
            _validateValidQuestionId(_cid, _current_qid),
            "Invaild Question Id"
        );
        require(
            _validateNofAnswersLimit(_cid),
            "Limit of Number of Users already reached"
        );
        require(
            _validateQuestionForSubmit(_cid),
            "Not a valid Question anymore"
        ); // Checks if question is a valid question for sumbit as of block.timestamp
        require(
            !_validateIfUserSubmitted(_cid),
            "Already SUBMITTED ans for this question"
        );

        DataTypes.UserAnswers memory userAnswer;
        userAnswer.status = DataTypes.Status.SUBMITTED;
        userAnswer.submittedCycleId = _cid;
        userAnswer.submittedDate = block.timestamp;
        userAnswer.answer = _encryptedAns;
        userAnswer.SUBMITTED = true;

        CURRENT_UserAnswers[msg.sender].push(userAnswer);

        currentQuestions[_cid].usersAnswered.push(msg.sender);
        currentQuestions[_cid].numOfAnswersGiven++;

        return true;
    }

    function _validateValidQuestionId(
        uint256 _cid,
        uint256 _qid
    ) internal view returns (bool) {
        return currentQuestions[_cid].questionId == _qid;
    }

    function _validateNofAnswersLimit(
        uint256 _cid
    ) internal view returns (bool) {
        return
            currentQuestions[_cid].numOfAnswersGiven <
            currentQuestions[_cid].numOfAnswersLimit;
    }

    function _validateQuestionForSubmit(
        uint256 _cid
    ) internal view returns (bool) {
        return
            currentQuestions[_cid].currentStartDate <= block.timestamp &&
            currentQuestions[_cid].currentSubmitEndDate >= block.timestamp;
    }

    function getQuestionForCommit() public view returns (uint256[] memory) {
        uint256[] memory submittedQuestions = new uint256[](
            _getCountForQuestionCommit()
        );
        uint256 counter = 0;

        for (uint256 i = 0; i < CURRENT_UserAnswers[msg.sender].length; i++) {
            uint256 cid = CURRENT_UserAnswers[msg.sender][i].submittedCycleId;
            if (
                !CURRENT_UserAnswers[msg.sender][i].COMMITTED &&
                block.timestamp < currentQuestions[cid].currentCommitDateEnd
            ) {
                submittedQuestions[counter] = CURRENT_UserAnswers[msg.sender][i]
                    .submittedCycleId;
                counter++;
            }
        }
        return submittedQuestions;
    }

    function _getCountForQuestionCommit() internal view returns (uint256) {
        uint256 count = 1;
        for (uint256 i = 0; i < CURRENT_UserAnswers[msg.sender].length; i++) {
            if (!CURRENT_UserAnswers[msg.sender][i].COMMITTED) {
                count++;
            }
        }
        return count;
    }

    function getQuestionDetailsForCommit(
        uint256 _cid
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            string memory,
            string memory,
            uint256
        )
    {
        if (_validateIfUserSubmitted(_cid) && !_validateIfUserCommitted(_cid)) {
            uint256 _index = currentQuestions[_cid].questionId;
            return (
                currentQuestions[_cid].cycleId,
                currentQuestions[_cid].questionId,
                currentQuestions[_cid].currentCommitDateStart,
                currentQuestions[_cid].currentCommitDateEnd,
                questions[_index].questionText,
                CURRENT_UserAnswers[msg.sender][
                    _getCommitIndexOfCurrentUser(_cid)
                ].answer,
                _getCommitIndexOfCurrentUser(_cid)
            );
        }
    }

    function _getCommitIndexOfCurrentUser(
        uint256 _cid
    ) internal view returns (uint256) {
        for (uint256 i = 0; i < CURRENT_UserAnswers[msg.sender].length; i++) {
            if (CURRENT_UserAnswers[msg.sender][i].submittedCycleId == _cid) {
                return i;
            }
        }
    }

    function validateQuestionForCommit(
        uint256 _cid
    ) public view returns (bool) {
        return
            currentQuestions[_cid].currentCommitDateStart <= block.timestamp &&
            currentQuestions[_cid].currentCommitDateEnd >= block.timestamp;
    }

    function _validateIfUserSubmitted(
        uint256 _cid
    ) internal view returns (bool) {
        for (
            uint256 i = 0;
            i < currentQuestions[_cid].usersAnswered.length;
            i++
        ) {
            if (currentQuestions[_cid].usersAnswered[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function _validateIfUserCommitted(
        uint256 _cid
    ) internal view returns (bool) {
        for (
            uint256 i = 0;
            i < currentQuestions[_cid].usersCommitted.length;
            i++
        ) {
            if (currentQuestions[_cid].usersCommitted[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function commitAnswer(
        uint256 _index,
        uint256 _cid,
        uint256 _qid,
        string memory _ans
    ) public returns (bool success) {
        require(
            _validateIfUserSubmitted(_cid),
            "Question needs to be SUBMITTED first."
        );
        require(!_validateIfUserCommitted(_cid), "Answer already COMMITTED.");
        require(
            validateQuestionForCommit(_cid),
            "User is commiting before or after commit date interval"
        );

        DataTypes.UserAnswers memory userAnswer = CURRENT_UserAnswers[
            msg.sender
        ][_index];
        userAnswer.status = DataTypes.Status.COMMITTED;
        userAnswer.commitedCycleId = _qid;
        userAnswer.committedDate = block.timestamp;
        userAnswer.answer = _ans;
        userAnswer.COMMITTED = true;

        CURRENT_UserAnswers[msg.sender][_index] = userAnswer;

        currentQuestions[_cid].usersCommitted.push(msg.sender);
        currentQuestions[_cid].committedAnswerTexts.push(_ans);

        return true;
    }

    function getCycleIdsForQuestionSummary()
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory summary_questions = new uint256[](getCountForReward());
        uint256 counter = 0;
        for (uint256 i = 0; i < CURRENT_UserAnswers[msg.sender].length; i++) {
            uint256 _curr_cid = CURRENT_UserAnswers[msg.sender][i]
                .commitedCycleId;
            if (
                CURRENT_UserAnswers[msg.sender][i].SUBMITTED &&
                CURRENT_UserAnswers[msg.sender][i].COMMITTED
            ) {
                summary_questions[counter] = CURRENT_UserAnswers[msg.sender][i]
                    .submittedCycleId;
                counter++;
            }
        }
        return summary_questions;
    }

    function getCountForReward() internal view returns (uint256) {
        uint256 counter = 1;
        for (uint256 i = 0; i < CURRENT_UserAnswers[msg.sender].length; i++) {
            uint256 _curr_cid = CURRENT_UserAnswers[msg.sender][i]
                .submittedCycleId;
            if (
                currentQuestions[_curr_cid].currentResultDate <= block.timestamp
            ) {
                if (
                    CURRENT_UserAnswers[msg.sender][i].SUBMITTED &&
                    CURRENT_UserAnswers[msg.sender][i].COMMITTED
                ) {
                    counter++;
                }
            }
        }
        return counter;
    }

    function getSummaryOfWinningQuestion(
        uint256 _cid
    ) public view returns (uint256, string memory, string memory) {
        uint256 winning_cycleID;
        string memory reward_calculation;
        string memory user_answer;
        for (uint256 i = 0; i < CURRENT_UserAnswers[msg.sender].length; i++) {
            if (
                CURRENT_UserAnswers[msg.sender][i].SUBMITTED &&
                CURRENT_UserAnswers[msg.sender][i].COMMITTED &&
                CURRENT_UserAnswers[msg.sender][i].submittedCycleId == _cid
            ) {
                uint256 result = _calculateResult(
                    _cid,
                    questions[currentQuestions[_cid].questionId].numOfAnswers,
                    questions[currentQuestions[_cid].questionId].answers,
                    CURRENT_UserAnswers[msg.sender][i].answer
                );
                winning_cycleID = _cid;
                user_answer = CURRENT_UserAnswers[msg.sender][i].answer;
                if (!currentQuestions[_cid].rewardCalculated) {
                    if (result == 2) {
                        reward_calculation = "false_Claim";
                    } else if (result == 1) {
                        reward_calculation = "false_Claim Refund";
                    } else if (result == 0) {
                        reward_calculation = "true_Lost";
                    }
                } else if (currentQuestions[_cid].rewardCalculated) {
                    if (result == 2) {
                        reward_calculation = "true_Rewarded";
                    } else if (result == 1) {
                        reward_calculation = "true_Refunded";
                    } else if (result == 0) {
                        reward_calculation = "true_Lost";
                    }
                }
            }
        }
        return (winning_cycleID, reward_calculation, user_answer);
    }

    function returnWinningDetails(
        uint256 _cid
    )
        public
        view
        returns (string memory, string memory, uint256, bool, string memory)
    {
        return (
            currentQuestions[_cid].winningAnswer,
            questions[currentQuestions[_cid].questionId].answers,
            currentQuestions[_cid].currentResultDate,
            currentQuestions[_cid].currentResultDate >= block.timestamp,
            questions[currentQuestions[_cid].questionId].questionText
        );
    }

    function returnWinningAns(
        uint256 _cid
    ) public view returns (string memory) {
        string[] memory answersArray = new string[](
            questions[currentQuestions[_cid].questionId].numOfAnswers
        );
        uint256[] memory answerCountArray = new uint256[](
            questions[currentQuestions[_cid].questionId].numOfAnswers
        );
        string[] memory commitAnsText = currentQuestions[_cid]
            .committedAnswerTexts;

        strings.slice memory s = questions[currentQuestions[_cid].questionId]
            .answers
            .toSlice();
        strings.slice memory delim = "_".toSlice();
        for (
            uint256 i = 0;
            i < questions[currentQuestions[_cid].questionId].numOfAnswers;
            i++
        ) {
            answersArray[i] = s.split(delim).toString();
            answerCountArray[i] = 0;
        }

        for (uint256 j = 0; j < answersArray.length; j++) {
            for (uint256 k = 0; k < commitAnsText.length; k++) {
                if (compareStrings(answersArray[j], commitAnsText[k])) {
                    answerCountArray[j] += 1;
                }
            }
        }

        if (findIndexOf(answerCountArray, 0) > -1) {
            for (uint256 j = 0; j < answerCountArray.length; j++) {
                if (answerCountArray[j] == 0) {
                    return answersArray[j];
                }
            }
        } else {
            if (
                _checkIfMinorityHasDuplicates(
                    answerCountArray,
                    _findMinCount(answerCountArray, 0)
                )
            ) {
                return "No_Winning_Ans";
            } else {
                return
                    answersArray[
                        _findIndexOfMinority(
                            _findMinCount(answerCountArray, 0),
                            answersArray.length,
                            answerCountArray
                        )
                    ];
            }
        }
    }

    function _calculateResult(
        uint256 _cid,
        uint256 _ansCount,
        string memory _answers,
        string memory _userAns
    ) internal view returns (uint256) {
        string[] memory answersArray = new string[](_ansCount);
        uint256[] memory answerCountArray = new uint256[](_ansCount);
        string[] memory commitAnsText = currentQuestions[_cid]
            .committedAnswerTexts; // all given answer by users.

        strings.slice memory s = _answers.toSlice();
        strings.slice memory delim = "_".toSlice();
        for (uint256 i = 0; i < _ansCount; i++) {
            answersArray[i] = s.split(delim).toString();
            answerCountArray[i] = 0;
        }

        for (uint256 j = 0; j < answersArray.length; j++) {
            for (uint256 k = 0; k < commitAnsText.length; k++) {
                if (compareStrings(answersArray[j], commitAnsText[k])) {
                    answerCountArray[j] += 1;
                }
            }
        }

        // 0 - do not show
        // 1 - claim refund
        // 2 - claim reward
        if (findIndexOf(answerCountArray, 0) > -1) {
            return 0;
        } else {
            if (
                _checkIfMinorityHasDuplicates(
                    answerCountArray,
                    _findMinCount(answerCountArray, 0)
                )
            ) {
                return 1;
            } else {
                if (
                    compareStrings(
                        answersArray[
                            _findIndexOfMinority(
                                _findMinCount(answerCountArray, 0),
                                answersArray.length,
                                answerCountArray
                            )
                        ],
                        _userAns
                    )
                ) {
                    // currentQuestions[_cid].winningAnswer = answersArray[
                    //     _findIndexOfMinority(
                    //         _findMinCount(answerCountArray, 0),
                    //         answersArray.length,
                    //         answerCountArray
                    //     )
                    // ];
                    return 2;
                } else {
                    // currentQuestions[_cid].winningAnswer = answersArray[
                    //     _findIndexOfMinority(
                    //         _findMinCount(answerCountArray, 0),
                    //         answersArray.length,
                    //         answerCountArray
                    //     )
                    // ];
                    return 0;
                }
            }
        }
    }

    function _findMinCount(
        uint256[] memory _array,
        uint256 minCount
    ) internal pure returns (uint256) {
        uint256 min_count = 0;
        uint256 min_check = _array[0];
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] > 0) {
                if (_array[i] <= min_check) {
                    min_check = _array[i];
                    min_count = _array[i];
                }
                //   break;
            }
        }
        return min_count;
    }

    function getWithrawableAmount() public view onlyOwner returns (uint256) {
        return totalWithdrawableAmount;
    }

    function _findIndexOfMinority(
        uint256 minCount,
        uint256 _ansArraylength,
        uint256[] memory _ansCountArray
    ) internal pure returns (uint256) {
        uint256 ans_index = 0;
        for (uint256 i = 0; i < _ansArraylength; i++) {
            if (_ansCountArray[i] <= minCount) {
                minCount = _ansCountArray[i];
                ans_index = i;
            }
        }
        return ans_index;
    }

    function _checkIfMinorityHasDuplicates(
        uint256[] memory _array,
        uint256 value
    ) internal pure returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] == value) {
                count++;
            }
        }
        return (count > 1);
    }

    function findIndexOf(
        uint256[] memory values,
        uint256 value
    ) internal pure returns (int) {
        for (int i = 0; i < int(values.length); i++) {
            if (values[uint256(i)] == value) return i;
        }
        return -1;
    }

    function compareStrings(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function claimReward(uint256 _cid) public returns (bool) {
        require(
            !currentQuestions[_cid].rewardCalculated,
            "Reward already calculated for this question."
        );
        uint256 rewardDistributed = 0;
        for (
            uint256 i = 0;
            i < currentQuestions[_cid].usersCommitted.length;
            i++
        ) {
            address _userAddress = currentQuestions[_cid].usersCommitted[i];
            for (
                uint256 j = 0;
                j < CURRENT_UserAnswers[_userAddress].length;
                j++
            ) {
                if (
                    CURRENT_UserAnswers[_userAddress][j].SUBMITTED &&
                    CURRENT_UserAnswers[_userAddress][j].COMMITTED &&
                    CURRENT_UserAnswers[_userAddress][j].submittedCycleId ==
                    _cid
                ) {
                    uint256 result = _calculateResult(
                        _cid,
                        questions[currentQuestions[_cid].questionId]
                            .numOfAnswers,
                        questions[currentQuestions[_cid].questionId].answers,
                        CURRENT_UserAnswers[_userAddress][j].answer
                    );
                    if (result == 2) {
                        uint256 doubleAmount = questions[
                            currentQuestions[_cid].questionId
                        ].cost * 2;
                        currentQuestions[_cid].rewardCalculated = true;
                        CURRENT_UserAnswers[_userAddress][j].resultDate = block
                            .timestamp;
                        CURRENT_UserAnswers[_userAddress][j].status = DataTypes
                            .Status
                            .RESULT_DECLARED;
                        userBalance[_userAddress] += doubleAmount;
                        rewardDistributed += doubleAmount;
                        emit logTransfer(
                            address(this),
                            _userAddress,
                            doubleAmount
                        );
                        Address.sendValue(payable(_userAddress), doubleAmount);
                    } else if (result == 1) {
                        uint256 amount = questions[
                            currentQuestions[_cid].questionId
                        ].cost;
                        currentQuestions[_cid].rewardCalculated = true;
                        CURRENT_UserAnswers[_userAddress][j].resultDate = block
                            .timestamp;
                        CURRENT_UserAnswers[_userAddress][j].status = DataTypes
                            .Status
                            .RESULT_DECLARED;
                        rewardDistributed += amount;
                        emit logTransfer(address(this), _userAddress, amount);
                        Address.sendValue(payable(_userAddress), amount);
                    }
                }
            }
        }

        if (currentQuestions[_cid].usersAnswered.length > 0) {
            totalWithdrawableAmount +=
                (currentQuestions[_cid].usersAnswered.length *
                    questions[currentQuestions[_cid].questionId].cost) -
                rewardDistributed;
        }

        if (
            questions[currentQuestions[_cid].questionId].repeatCnt <
            questions[currentQuestions[_cid].questionId].repeatLimit
        ) {
            addQuestionToCycle(
                currentCycleId,
                currentQuestions[_cid].questionId,
                _cid
            );
            questions[currentQuestions[_cid].questionId].repeatCnt += 1;
        }

        return true;
    }

    function getQuestionSubmitted(
        uint256 index
    )
        public
        view
        returns (
            uint256,
            string memory,
            uint256,
            uint256,
            uint256,
            string memory,
            uint256
        )
    {
        DataTypes.QuestionCycle memory cycle = currentQuestions[index];
        DataTypes.Question memory question = questions[cycle.questionId];
        if (
            cycle.currentResultDate < block.timestamp && !cycle.rewardCalculated
        ) {
            return (
                cycle.cycleId,
                question.questionText,
                question.cost,
                question.repeatLimit,
                cycle.currentStartDate,
                calculateResultAdmin(index),
                cycle.questionId
            );
        } else {
            if (!cycle.rewardCalculated) {
                return (
                    cycle.cycleId,
                    question.questionText,
                    question.cost,
                    question.repeatLimit,
                    cycle.currentStartDate,
                    "false_Distribute Reward",
                    cycle.questionId
                );
            } else if (
                cycle.rewardCalculated &&
                question.repeatCnt == question.repeatLimit
            ) {
                return (
                    cycle.cycleId,
                    question.questionText,
                    question.cost,
                    question.repeatLimit,
                    cycle.currentStartDate,
                    "false_NoAction",
                    cycle.questionId
                );
            }
        }
    }

    function calculateResultAdmin(
        uint256 _cid
    ) public view returns (string memory) {
        string[] memory answersArray = new string[](
            questions[currentQuestions[_cid].questionId].numOfAnswers
        );
        uint256[] memory answerCountArray = new uint256[](
            questions[currentQuestions[_cid].questionId].numOfAnswers
        );
        string[] memory commitAnsText = currentQuestions[_cid]
            .committedAnswerTexts;
        uint256 minCount = 0;

        strings.slice memory s = questions[currentQuestions[_cid].questionId]
            .answers
            .toSlice();
        strings.slice memory delim = "_".toSlice();
        for (
            uint256 i = 0;
            i < questions[currentQuestions[_cid].questionId].numOfAnswers;
            i++
        ) {
            answersArray[i] = s.split(delim).toString();
            answerCountArray[i] = 0;
        }

        for (uint256 j = 0; j < answersArray.length; j++) {
            for (uint256 k = 0; k < commitAnsText.length; k++) {
                if (compareStrings(answersArray[j], commitAnsText[k])) {
                    answerCountArray[j] += 1;
                }
            }
        }

        if (findIndexOf(answerCountArray, 0) > -1) {
            if (
                questions[currentQuestions[_cid].questionId].repeatCnt <
                questions[currentQuestions[_cid].questionId].repeatLimit
            ) {
                // questions[currentQuestions[_cid].questionId].repeatCnt += 1;
                return "next_Start Next Cycle";
            } else {
                return "false_NoAction";
            }
        } else {
            if (
                _checkIfMinorityHasDuplicates(
                    answerCountArray,
                    _findMinCount(answerCountArray, minCount)
                )
            ) {
                return "true_Issue Refund";
            } else {
                return "true_Distribute Reward";
            }
        }
    }

    function issueRefundByAdmin(uint256 _cid) public onlyOwner returns (bool) {
        require(
            !currentQuestions[_cid].rewardCalculated,
            "Reward already calculated for this question."
        );
        uint256 rewardDistributed = 0;
        for (
            uint256 i = 0;
            i < currentQuestions[_cid].usersCommitted.length;
            i++
        ) {
            address _userAddress = currentQuestions[_cid].usersCommitted[i];
            for (
                uint256 j = 0;
                j < CURRENT_UserAnswers[_userAddress].length;
                j++
            ) {
                if (
                    CURRENT_UserAnswers[_userAddress][j].SUBMITTED &&
                    CURRENT_UserAnswers[_userAddress][j].COMMITTED &&
                    CURRENT_UserAnswers[_userAddress][j].submittedCycleId ==
                    _cid
                ) {
                    uint256 amount = questions[
                        currentQuestions[_cid].questionId
                    ].cost;
                    currentQuestions[_cid].rewardCalculated = true;
                    CURRENT_UserAnswers[_userAddress][j].resultDate = block
                        .timestamp;
                    CURRENT_UserAnswers[_userAddress][j].status = DataTypes
                        .Status
                        .RESULT_DECLARED;
                    Address.sendValue(payable(_userAddress), amount);
                    rewardDistributed += amount;
                    //   userBalance[_userAddress] += amount;
                    emit logTransfer(address(this), _userAddress, amount);
                }
            }
        }
        if (currentQuestions[_cid].usersAnswered.length > 0) {
            totalWithdrawableAmount +=
                (currentQuestions[_cid].usersAnswered.length *
                    questions[currentQuestions[_cid].questionId].cost) -
                rewardDistributed;
        }

        if (
            questions[currentQuestions[_cid].questionId].repeatCnt <
            questions[currentQuestions[_cid].questionId].repeatLimit
        ) {
            addQuestionToCycle(
                currentCycleId,
                currentQuestions[_cid].questionId,
                _cid
            );
            questions[currentQuestions[_cid].questionId].repeatCnt += 1;
        }

        return true;
    }

    function getCurrentQuestionDetails(
        uint256 _cycle_id
    ) public view returns (address[] memory, address[] memory) {
        return (
            currentQuestions[_cycle_id].usersAnswered,
            currentQuestions[_cycle_id].usersCommitted
        );
    }

    function endQuestionCycle(uint256 _cid) public {
        require(
            questions[currentQuestions[_cid].questionId].repeatCnt ==
                questions[currentQuestions[_cid].questionId].repeatLimit,
            "Cycle still left  or completed"
        );
        currentQuestions[_cid].rewardCalculated = true;
        questions[currentQuestions[_cid].questionId].repeatCnt += 1;
        if (currentQuestions[_cid].usersAnswered.length > 0) {
            totalWithdrawableAmount += (currentQuestions[_cid]
                .usersAnswered
                .length * questions[currentQuestions[_cid].questionId].cost);
        }
    }

    function addQuestionToCycle(
        uint256 _cid,
        uint256 _qid,
        uint256 _current_cid
    ) internal {
        currentQuestions[_cid].cycleId = _cid;
        currentQuestions[_cid].questionId = _qid;

        if (currentQuestions[_current_cid].nextStartDate < block.timestamp) {
            currentQuestions[_cid].currentStartDate = block.timestamp;
        } else {
            currentQuestions[_cid].currentStartDate = currentQuestions[
                _current_cid
            ].nextStartDate;
        }

        currentQuestions[_cid].currentSubmitEndDate =
            currentQuestions[_cid].currentStartDate +
            questions[currentQuestions[_current_cid].questionId]
                .numOfDaysSubmit;
        currentQuestions[_cid].currentCommitDateStart = currentQuestions[_cid]
            .currentSubmitEndDate;
        currentQuestions[_cid].currentCommitDateEnd =
            currentQuestions[_cid].currentCommitDateStart +
            questions[currentQuestions[_current_cid].questionId]
                .numOfDaysCommit;
        currentQuestions[_cid].currentResultDate =
            currentQuestions[_cid].currentCommitDateEnd +
            questions[currentQuestions[_current_cid].questionId]
                .numOfDaysBeforeResult;
        currentQuestions[_cid].nextStartDate =
            currentQuestions[_cid].currentCommitDateEnd +
            questions[currentQuestions[_current_cid].questionId]
                .numOfDaysBeforeResult +
            questions[currentQuestions[_current_cid].questionId]
                .numOfDaysRepeatAfterResult;
        currentQuestions[_cid].numOfAnswersLimit = questions[
            currentQuestions[_current_cid].questionId
        ].numOfAnswersLimit;
        //questions[currentQuestions[_current_cid].questionId].repeatLimit -= 1;

        currentCycleId++;
    }

    function startNextCycle(
        uint256 _cid,
        uint256 _current_cid
    ) public onlyOwner {
        require(
            questions[currentQuestions[_current_cid].questionId].repeatCnt <
                questions[currentQuestions[_current_cid].questionId]
                    .repeatLimit,
            "Already added to cycle."
        );
        require(
            !currentQuestions[_current_cid].rewardCalculated,
            "Reward already calculated for this question."
        );
        currentQuestions[_cid].cycleId = _cid;
        currentQuestions[_cid].questionId = currentQuestions[_current_cid]
            .questionId;

        if (currentQuestions[_current_cid].nextStartDate < block.timestamp) {
            currentQuestions[_cid].currentStartDate = block.timestamp;
        } else {
            currentQuestions[_cid].currentStartDate = currentQuestions[
                _current_cid
            ].nextStartDate;
        }

        currentQuestions[_cid].currentSubmitEndDate =
            currentQuestions[_cid].currentStartDate +
            questions[currentQuestions[_current_cid].questionId]
                .numOfDaysSubmit;
        currentQuestions[_cid].currentCommitDateStart = currentQuestions[_cid]
            .currentSubmitEndDate;
        currentQuestions[_cid].currentCommitDateEnd =
            currentQuestions[_cid].currentCommitDateStart +
            questions[currentQuestions[_current_cid].questionId]
                .numOfDaysCommit;
        currentQuestions[_cid].currentResultDate =
            currentQuestions[_cid].currentCommitDateEnd +
            questions[currentQuestions[_current_cid].questionId]
                .numOfDaysBeforeResult;
        currentQuestions[_cid].nextStartDate =
            currentQuestions[_cid].currentCommitDateEnd +
            questions[currentQuestions[_current_cid].questionId]
                .numOfDaysBeforeResult +
            questions[currentQuestions[_current_cid].questionId]
                .numOfDaysRepeatAfterResult;
        currentQuestions[_cid].numOfAnswersLimit = questions[
            currentQuestions[_current_cid].questionId
        ].numOfAnswersLimit;
        questions[currentQuestions[_current_cid].questionId].repeatCnt += 1;
        //questions[currentQuestions[_current_cid].questionId].repeatLimit -= 1;
        currentQuestions[_current_cid].rewardCalculated = true;

        if (currentQuestions[_current_cid].usersAnswered.length > 0) {
            totalWithdrawableAmount += (currentQuestions[_current_cid]
                .usersAnswered
                .length *
                questions[currentQuestions[_current_cid].questionId].cost);
        }

        currentCycleId++;
    }

    function withdrawAmount(
        address payable to,
        uint256 amount
    ) public onlyOwner {
        require(
            amount <= totalWithdrawableAmount,
            "amount is greater than withdrawable amount."
        );
        totalWithdrawableAmount = totalWithdrawableAmount - amount;
        Address.sendValue(to, amount);
    }
}
