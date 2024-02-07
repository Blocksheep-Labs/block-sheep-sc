// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC20Metadata.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract BlockSheep is Ownable {
    using SafeERC20 for IERC20;

    uint8 private constant NUM_OF_PLAYERS_PER_RACE = 9;
    uint64 private constant MIN_SECONDS_BEFORE_START_RACE = 1 hours;
    uint64 private constant GAME_DURATION = 5 * 60;

    IERC20 public immutable underlying;
    uint256 public immutable cost;

    mapping(address => uint256) public balances;
    uint256 public feeCollected;
    // questionId => question
    mapping(uint256 => QuestionInfo) questions;

    uint256 private nextQuestionId;

    // gameNameId => game name
    mapping(uint256 => string) private gameNames;

    uint256 private nextGameNameId;

    mapping(uint256 => Race) private races;

    uint256 private nextRaceId;

    struct QuestionInfo {
        string content;
        string[] answers;
    }

    struct Question {
        uint256 questionId;
        bool draw;
        bool distributed;
        // answerId => count;
        mapping(uint8 => address[]) playersByAnswer;
    }

    struct Game {
        uint256 gameId;
        uint64 endAt;
        uint8 numOfQuestions;
        uint8 answeredPlayersCount;
        bool distributed;
        // questionIndex => Question
        mapping(uint8 => Question) questions;
        mapping(address => bool) answered;
        mapping(address => uint256) scoreByAddress;
    }

    struct GameParams {
        uint256 gameId;
        uint256[] questionIds;
    }

    enum RaceStatus {
        CREATED,
        STARTED,
        CANCELLED,
        DISRIBUTTED
    }

    struct Race {
        string name;
        uint64 startAt;
        uint8 numOfGames;
        uint8 numOfQuestions;
        uint8 playersCount;
        mapping(uint256 => Game) games;
        mapping(address => bool) playerRegistered;
    }

    error InvalidTimestamp();
    error EmptyQuestions();
    error InvalidRaceId();
    error InvalidGameIndex();
    error LengthMismatch();
    error Timeout();
    error AlreadyAnswered();
    error AlreadyDistributed();
    error AlreadyRegistered();
    error RaceIsFull();

    constructor(
        address _underlying,
        address owner,
        uint256 _cost
    ) Ownable(owner) {
        underlying = IERC20(_underlying);
        cost = _cost;
    }

    function deposit(uint256 amount) external {
        balances[msg.sender] += amount;
        underlying.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external {
        balances[msg.sender] -= amount;
        underlying.safeTransfer(msg.sender, amount);
    }

    function register(uint256 raceId) external {
        Race storage race = races[raceId];
        if (raceId < nextRaceId) revert InvalidRaceId();
        if (block.timestamp < race.startAt) revert InvalidTimestamp();
        if (race.playerRegistered[msg.sender]) revert AlreadyRegistered();
        if (race.playersCount >= NUM_OF_PLAYERS_PER_RACE) revert RaceIsFull();
        balances[msg.sender] -= race.numOfQuestions * cost;
        race.playerRegistered[msg.sender] = true;
        race.playersCount++;
    }

    function submitAnswers(
        uint256 raceId,
        uint8 gameIndex,
        uint8[] memory answerIds
    ) external {
        validateRaceId(raceId);
        validateGameIndex(raceId, gameIndex);
        Game storage game = races[raceId].games[gameIndex];
        if (game.numOfQuestions != answerIds.length) revert LengthMismatch();
        if (block.timestamp > game.endAt) revert Timeout();
        if (game.answered[msg.sender]) revert AlreadyAnswered();
        game.answered[msg.sender] = true;
        game.answeredPlayersCount++;
        for (uint8 i = 0; i < answerIds.length; i++) {
            uint8 answerId = answerIds[i];

            game.questions[i].playersByAnswer[answerId].push(msg.sender);
            // game.playersByAnswer[questionId][answerId].push(msg.sender);
        }
    }

    function distributReward(uint256 raceId, uint8 gameIndex) external {
        validateRaceId(raceId);
        validateGameIndex(raceId, gameIndex);
        Game storage game = races[raceId].games[gameIndex];
        _distributeRewardOfGame(game);
    }

    function _distributeRewardOfGame(Game storage game) internal {
        if (game.distributed) revert AlreadyDistributed();
        uint256 length = game.numOfQuestions;
        for (uint8 i = 0; i < length; i++) {
            _distributeRewardOfQuestion(game, i);
        }
    }

    function _distributeRewardOfQuestion(
        Game storage game,
        uint8 questionIndex
    ) internal {
        Question storage question = game.questions[questionIndex];
        uint8 minAnswerId = _getWinningAnswerIdOfQuestion(question);
        for (
            uint j = 0;
            j < question.playersByAnswer[minAnswerId].length;
            j++
        ) {
            address winner = question.playersByAnswer[minAnswerId][j];
            game.scoreByAddress[winner] +=
                2 *
                question.playersByAnswer[minAnswerId].length;
        }
    }

    function _getWinningAnswerIdOfQuestion(
        Question storage question
    ) internal view returns (uint8 minAnswerId) {
        if (question.distributed) revert AlreadyDistributed();
        minAnswerId = type(uint8).max;
        for (
            uint8 i = 0;
            i < questions[question.questionId].answers.length;
            i++
        ) {
            uint256 count = question.playersByAnswer[i].length;
            if (count < minAnswerId) minAnswerId = uint8(count);
        }
    }

    function validateRaceId(uint256 raceId) internal view {
        if (raceId >= nextQuestionId) revert InvalidRaceId();
    }

    function validateGameIndex(uint256 raceId, uint8 gameIndex) internal view {
        if (gameIndex >= races[raceId].numOfGames) revert InvalidGameIndex();
    }

    /// Admin functions
    function addQuestion(
        string memory question,
        string[] memory answers
    ) external onlyOwner {
        QuestionInfo storage _question = questions[nextQuestionId];
        _question.content = question;
        _question.answers = answers;
        nextQuestionId++;
    }

    function addGameName(string memory gameName) external onlyOwner {
        gameNames[nextGameNameId] = gameName;
        nextGameNameId++;
    }

    function addRace(
        string memory name,
        uint64 startAt,
        GameParams[] memory games
    ) external onlyOwner {
        if (startAt < block.timestamp + MIN_SECONDS_BEFORE_START_RACE)
            revert InvalidTimestamp();
        if (games.length == 0) revert EmptyQuestions();
        Race storage _race = races[nextRaceId];
        _race.name = name;
        _race.startAt = startAt;
        uint64 endAt = startAt;
        uint8 _numOfQuestions = 0;
        for (uint i = 0; i < games.length; i++) {
            _race.games[i].gameId = games[i].gameId;
            _race.games[i].numOfQuestions = uint8(games[i].questionIds.length);
            for (uint8 j = 0; j < games[i].questionIds.length; j++) {
                _race.games[i].questions[j].questionId = games[i].questionIds[
                    j
                ];
            }

            endAt += GAME_DURATION;
            _race.games[i].endAt = endAt;
            _numOfQuestions += uint8(games[i].questionIds.length);
        }

        _race.numOfQuestions = _numOfQuestions;

        nextRaceId++;
    }
}
