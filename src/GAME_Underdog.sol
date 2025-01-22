// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract GAME_Underdog {
    // User choices by raceId, user address, and questionIndex
    mapping(uint256 => mapping(address => mapping(uint8 => uint8))) private UNDERDOG_usersChoices;

    // Track answer states (answered or not) for each question
    mapping(uint256 => mapping(address => mapping(uint8 => bool))) private UNDERDOG_usersAnswers;

    // Store questions for each raceId
    mapping(uint256 => QuestionInfo[]) private UNDERDOG_questions;

    // Users' points by raceId and address
    mapping(uint256 => mapping(address => uint8)) private UNDERDOG_points;

    // Track if points have been distributed for each question
    mapping(uint256 => mapping(uint8 => bool)) private UNDERDOG_pointsDistributed;

    // Store players who answered each question for each race
    mapping(uint256 => mapping(uint8 => address[])) private UNDERDOG_answeredPlayers;


    struct QuestionInfo {
        string content;
        string[] answers;
        string imgUrl;
    }

    struct QuestionInfoReturnType {
        uint256 id;
        QuestionInfo info;
    }

    function initRace(
        uint256 raceId,
        bytes calldata initState
    ) public {
        QuestionInfo[] memory questionsInfo = abi.decode(initState, (QuestionInfo[]));
        // Set the questions for the given raceId
        delete UNDERDOG_questions[raceId];  // Clear any existing questions
        for (uint256 i = 0; i < questionsInfo.length; i++) {
            UNDERDOG_questions[raceId].push(questionsInfo[i]);
        }
    }

    function getWinner(uint256 raceId) public pure returns (address) {
        return address(0);
    }

    function getPoints(uint256 raceId) public view returns (uint256) {
        return UNDERDOG_points[raceId][msg.sender];
    }

    function getUserChoices(uint256 raceId) public view returns (uint8[] memory, uint8[] memory) {
        uint256 questionsCount = UNDERDOG_questions[raceId].length;

        uint8[] memory questionIndexes = new uint8[](questionsCount);
        uint8[] memory userChoices = new uint8[](questionsCount);

        // Loop through each question index and fetch the user's choice
        for (uint8 i = 0; i < questionsCount; i++) {
            questionIndexes[i] = i;
            userChoices[i] = UNDERDOG_usersChoices[raceId][msg.sender][i];
        }

        return (questionIndexes, userChoices);
    }

    function makeMove(
        uint256 raceId,
        uint8 questionIndex,
        uint8 answerIndex
    ) external {
        // Check if the player has already answered this question
        require(UNDERDOG_usersAnswers[raceId][msg.sender][questionIndex] == false, "Player has already answered this question");

        // Mark the question as answered and store the user's choice
        UNDERDOG_usersAnswers[raceId][msg.sender][questionIndex] = true;
        UNDERDOG_usersChoices[raceId][msg.sender][questionIndex] = answerIndex;

        // Add the player to the list of answered players for the specific question
        UNDERDOG_answeredPlayers[raceId][questionIndex].push(msg.sender);
    }

    function distribute(
        uint256 raceId
    ) external {
        // Iterate through the questions in the mapping and distribute rewards
        for (uint8 questionIndex = 0; questionIndex < UNDERDOG_questions[raceId].length; questionIndex++) {
            _distributeRewardOfQuestion(raceId, questionIndex);
        }
    }


    function getRules(
        uint256 raceId
    ) public view returns (QuestionInfoReturnType[] memory) {
        uint256 length = UNDERDOG_questions[raceId].length;

        // Initialize an array to store QuestionInfoReturnType structs
        QuestionInfoReturnType[] memory questionsInfo = new QuestionInfoReturnType[](length);

        // Populate the questionsInfo array
        for (uint8 i = 0; i < length; i++) {
            questionsInfo[i] = QuestionInfoReturnType({
                id: i,
                info: UNDERDOG_questions[raceId][i]
            });
        }

        // Return the populated questionsInfo array
        return questionsInfo;
    }



    function _distributeRewardOfQuestion(
        uint256 raceId,
        uint8 questionIndex
    ) internal {
        // Get the question info
        QuestionInfo[] storage questions = UNDERDOG_questions[raceId];

        // Ensure the question index is valid
        require(questionIndex < questions.length, "Invalid question index");

        // Get the players who answered and their choices
        address[] memory answeredPlayersList = UNDERDOG_answeredPlayers[raceId][questionIndex];
        uint256 totalPlayers = answeredPlayersList.length;

        // Count the answers for each choice
        uint256[] memory answerCounts = new uint256[](questions[questionIndex].answers.length);
        for (uint256 i = 0; i < totalPlayers; i++) {
            uint8 playerAnswer = UNDERDOG_usersChoices[raceId][answeredPlayersList[i]][questionIndex];
            answerCounts[playerAnswer]++;
        }

        // If it's a draw, skip reward distribution
        bool isDraw = true; // draw initially
        uint256 firstCount = answerCounts[0]; // Get the first count to compare against

        for (uint8 i = 1; i < answerCounts.length; i++) {
            if (answerCounts[i] != firstCount) {
                isDraw = false; // Found a count that is different
                break; // No need to check further
            }
        }

        if (isDraw) {
            return; // Skip reward distribution if it's a draw
        }

        // Determine the winning answer ID (answer with the most players)
        uint8 winningAnswerId = _getWinningAnswerId(answerCounts);

        // Distribute points for the winning answer
        for (uint256 i = 0; i < totalPlayers; i++) {
            // Check if points have already been distributed for this question
            if (!UNDERDOG_pointsDistributed[raceId][questionIndex]) {
                if (UNDERDOG_usersChoices[raceId][answeredPlayersList[i]][questionIndex] == winningAnswerId) {
                    UNDERDOG_points[raceId][answeredPlayersList[i]] += 1; // Update points for the winner
                }
            }
        }

        // Mark points as distributed for this question
        UNDERDOG_pointsDistributed[raceId][questionIndex] = true;
    }

    function _getWinningAnswerId(uint256[] memory answerCounts) internal pure returns (uint8) {
        uint8 winningAnswerId = 0;
        uint256 maxCount = 0;

        for (uint8 i = 0; i < answerCounts.length; i++) {
            if (answerCounts[i] > maxCount) {
                maxCount = answerCounts[i];
                winningAnswerId = i;
            }
        }

        return winningAnswerId;
    }
}
