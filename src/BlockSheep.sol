// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract BlockSheep is Ownable {
    using SafeERC20 for IERC20;

    uint8 private constant NUM_OF_PLAYERS_PER_RACE = 3;
    uint64 private constant MIN_SECONDS_BEFORE_START_RACE = 5 minutes;
    uint64 private constant GAME_DURATION = 5 * 60;

    IERC20 public immutable UNDERLYING;
    uint256 public immutable COST;

    mapping(address => uint256) public balances;
    uint256 public feeCollected;
    // questionId => question
    mapping(uint256 => QuestionInfo) public questions;

    uint256 private nextQuestionId;

    // gameNameId => game name
    mapping(uint256 => string) private gameNames;

    uint256 private nextGameNameId;

    mapping(uint256 => Race) private races;

    uint256 public nextRaceId;

    struct QuestionInfo {
        string content;
        string[] answers;
    }

    struct Question {
        uint256 questionId;
        bool draw;
        bool distributed;
        uint8 answeredPlayersCount;
        // answerId => count;
        mapping(uint8 => address[]) playersByAnswer;
        mapping(address => bool) answered;
    }

    struct Game {
        uint256 gameId;
        uint64 endAt;
        uint8 numOfQuestions;
        // questionIndex => Question
        mapping(uint8 => Question) questions;
        mapping(address => uint256) scoreByAddress;
    }

    struct GameParams {
        uint256 gameId;
        uint256[] questionIds;
    }

    enum RaceStatus {
        NON_EXIST,
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

    struct RaceInfo {
        string name;
        uint64 startAt;
        uint8 numOfGames;
        uint8 numOfQuestions;
        uint8 playersCount;
        bool registered;
        RaceStatus status;
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

    event Registered(address user, uint256 amount);

    constructor(
        address _underlying,
        address owner,
        uint256 _cost
    ) Ownable(owner) {
        UNDERLYING = IERC20(_underlying);
        COST = _cost;
    }

    function deposit(uint256 amount) external {
        balances[msg.sender] += amount;
        UNDERLYING.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external {
        balances[msg.sender] -= amount;
        UNDERLYING.safeTransfer(msg.sender, amount);
    }

    function register(uint256 raceId) external {
        Race storage race = races[raceId];
        if (raceId >= nextRaceId) revert InvalidRaceId();
        if (block.timestamp > race.startAt) revert InvalidTimestamp();
        if (race.playerRegistered[msg.sender]) revert AlreadyRegistered();
        if (race.playersCount >= NUM_OF_PLAYERS_PER_RACE) revert RaceIsFull();
        balances[msg.sender] -= race.numOfQuestions * COST;
        race.playerRegistered[msg.sender] = true;
        race.playersCount++;

        emit Registered(msg.sender, race.numOfQuestions * COST);
    }

    function submitAnswer(
        uint256 raceId,
        uint8 gameIndex,
        uint8 qIndex,
        uint8 aId
    ) external {
        validateRaceId(raceId);
        validateGameIndex(raceId, gameIndex);
        Game storage game = races[raceId].games[gameIndex];
        Question storage question = game.questions[qIndex];
        if (block.timestamp > game.endAt) revert Timeout();
        if (question.answered[msg.sender]) revert AlreadyAnswered();
        question.answered[msg.sender] = true;
        question.answeredPlayersCount++;
        question.playersByAnswer[aId].push(msg.sender);
    }

    function distributeReward(
        uint256 raceId,
        uint8 gameIndex,
        uint8 qIndex
    ) external {
        validateRaceId(raceId);
        validateGameIndex(raceId, gameIndex);
        Game storage game = races[raceId].games[gameIndex];
        _distributeRewardOfQuestion(game, qIndex);
    }

    function _distributeRewardOfQuestion(
        Game storage game,
        uint8 questionIndex
    ) internal {
        Question storage question = game.questions[questionIndex];
        uint8 minAnswerId = _getWinningAnswerIdOfQuestion(question);
        for (
            uint256 j = 0;
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

            if (count < minAnswerId) minAnswerId = i;
        }
    }

    function validateRaceId(uint256 raceId) internal view {
        if (raceId >= nextQuestionId) revert InvalidRaceId();
    }

    function validateGameIndex(uint256 raceId, uint8 gameIndex) internal view {
        if (gameIndex >= races[raceId].numOfGames) revert InvalidGameIndex();
    }

    /// Admin functions
    function addQuestion(QuestionInfo memory params) external onlyOwner {
        _addQuestion(params);
    }

    function addQuestions(QuestionInfo[] memory _questions) external onlyOwner {
        for (uint256 index = 0; index < _questions.length; index++) {
            _addQuestion(_questions[index]);
        }
    }

    function _addQuestion(QuestionInfo memory params) internal {
        QuestionInfo storage _question = questions[nextQuestionId];
        _question.content = params.content;
        _question.answers = params.answers;
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
        _race.numOfGames = uint8(games.length);
        uint64 endAt = startAt;
        uint8 _numOfQuestions = 0;
        for (uint256 i = 0; i < games.length; i++) {
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

    function getQuestions(
        uint256 id
    ) public view returns (QuestionInfo memory) {
        return questions[id];
    }

    function getGameNames(uint256 id) public view returns (string memory) {
        return gameNames[id];
    }

    function getRaces(
        uint256 id
    )
        public
        view
        returns (
            string memory name,
            uint64 startAt,
            uint8 numOfGames,
            uint8 numOfQuestions,
            uint8 playersCount
        )
    {
        Race storage race = races[id];
        name = race.name;
        startAt = race.startAt;
        numOfGames = race.numOfGames;
        numOfQuestions = race.numOfQuestions;
        playersCount = race.playersCount;
    }

    function getScoreAtGameOfUser(
        uint256 raceId,
        uint256 gameIndex,
        address user
    ) external view returns (uint256) {
        return races[raceId].games[gameIndex].scoreByAddress[user];
    }

    function getRacesWithPagination(
        address user,
        uint256 from,
        uint256 to
    ) external view returns (RaceInfo[] memory) {
        require(from < nextRaceId, "From index out of bounds");
        require(from < to, "To index must be greater than from index");

        if (to > nextRaceId) {
            to = nextRaceId;
        }
        uint256 length = to - from;
        RaceInfo[] memory _races = new RaceInfo[](length);
        for (uint256 index = 0; index < length; index++) {
            Race storage race = races[index];
            _races[index].name = race.name;
            _races[index].startAt = race.startAt;
            _races[index].numOfGames = race.numOfGames;
            _races[index].numOfQuestions = race.numOfQuestions;
            _races[index].playersCount = race.playersCount;
            _races[index].registered = race.playerRegistered[user];
        }
        return _races;
    }

    function getRaceStatus(uint256 raceId) external view returns (RaceStatus) {
        if (raceId > nextRaceId) return RaceStatus.NON_EXIST;
        Race storage race = races[raceId];
        if (race.startAt < block.timestamp) return RaceStatus.CREATED;
        if (race.playersCount < NUM_OF_PLAYERS_PER_RACE)
            return RaceStatus.CANCELLED;

        return RaceStatus.STARTED;
    }
}
