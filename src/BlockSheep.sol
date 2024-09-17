// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { GAME_Bullrun } from "./GAME_Bullrun.sol";

contract BlockSheep is Ownable {
    using SafeERC20 for IERC20;

    GAME_Bullrun BULLRUN;

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

    // list of admin access
    mapping(address => bool) public userHasAdminAccess;

    struct QuestionInfo {
        string content;
        string[] answers;
    }

    struct QuestionInfoReturnType {
        uint256 id;
        QuestionInfo info;
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

    struct RabbitTunnel {
        address[] usersAddresses;
        uint256[] fuelSubmissions;
        uint256[] fuelLeft;
        address[] finishedBy;
        address winner;
        
        address[] pointsAddresses;
        uint256[] pointsAmount;
    }

    struct Race {
        string name;
        uint64 startAt;
        uint8 numOfGames;
        uint8 numOfQuestions;
        mapping(uint256 => Game) games;
        mapping(address => bool) playerRegistered;
        mapping(address => uint256[]) gamesCompleted;
        mapping(address => bool) refunded;
        address[] registeredUsers;
        RabbitTunnel rabbitTunnel;
        uint8 numOfPlayersRequired;
        GAME_Bullrun BULLRUN;
    }

    struct RaceInfo {
        string name;
        uint64 startAt;
        uint8 numOfGames;
        uint8 numOfQuestions;
        bool registered;
        RaceStatus status;
        uint256[] games;
        uint256[] gamesCompletedPerUser;
        uint256 raceDuration;
        bool refunded;
        address[] registeredUsers;
        RabbitTunnel rabbitTunnel;
        uint8 numOfPlayersRequired;
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
    error NotRegistered();
    error AccessDenied();

    event Registered(address user, uint256 amount);

    constructor(
        address _underlying,
        address owner,
        uint256 _cost
    ) Ownable(owner) {
        UNDERLYING = IERC20(_underlying);
        COST = _cost;
        userHasAdminAccess[owner] = true;
        BULLRUN = new GAME_Bullrun(address(this));
    }

    function deposit(uint256 amount) external {
        if (amount <= 0) revert("Amount to buy must be greater than zero");

        UNDERLYING.safeTransferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) revert("Amount must be greater than zero");
        if (balances[msg.sender] < amount) revert("Insufficient balance");
        
        balances[msg.sender] -= amount;
        UNDERLYING.safeTransfer(msg.sender, amount);
    }

    function refundBalance(uint256 amount, uint256 raceId) external {
        Race storage race = races[raceId];
        if (race.startAt > block.timestamp) revert InvalidTimestamp();
        if (race.playerRegistered[msg.sender] == false) revert NotRegistered();

        balances[msg.sender] += amount;
        race.refunded[msg.sender] = true;
    }

    function register(uint256 raceId) external {
        Race storage race = races[raceId];
        if (raceId >= nextRaceId) revert InvalidRaceId();
        if (block.timestamp > race.startAt) revert InvalidTimestamp();
        if (race.playerRegistered[msg.sender]) revert AlreadyRegistered();
        if (race.registeredUsers.length >= race.numOfPlayersRequired) revert RaceIsFull();
        
        balances[msg.sender] -= race.numOfQuestions * COST;
        race.playerRegistered[msg.sender] = true;
        race.registeredUsers.push(msg.sender);

        emit Registered(msg.sender, race.numOfQuestions * COST);
    }

    function setAdminRights(address user, bool isAdmin) external onlyOwner {
        userHasAdminAccess[user] = isAdmin;
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

    
    function submitFuel(
        uint256 raceId,
        uint256 fuelSubmision,
        uint256 fuelLeft
    ) external {
        validateRaceId(raceId);
        RabbitTunnel storage rabbitTunnel = races[raceId].rabbitTunnel;

        rabbitTunnel.usersAddresses.push(msg.sender);
        rabbitTunnel.fuelSubmissions.push(fuelSubmision);
        rabbitTunnel.fuelLeft.push(fuelLeft);
    }

    function finishTunnelGame(
        uint256 raceId,
        bool isWon,
        uint256 pointsToAllocate
    ) external {
        validateRaceId(raceId);
        RabbitTunnel storage rabbitTunnel = races[raceId].rabbitTunnel;
        rabbitTunnel.pointsAddresses.push(msg.sender);
        rabbitTunnel.pointsAmount.push(pointsToAllocate);

        rabbitTunnel.finishedBy.push(msg.sender);
        if (isWon) {
            rabbitTunnel.winner = msg.sender;
        }
    }

    function distributeReward(
        uint256 raceId,
        uint8 gameIndex,
        uint8[] calldata qIndexes,
        bool isDraw,
        address distributer
    ) external {
        validateRaceId(raceId);
        validateGameIndex(raceId, gameIndex);
        Race storage race = races[raceId];

        if (isDraw == false) {
            Game storage game = race.games[gameIndex];
            for (uint8 i = 0; i < qIndexes.length; i++) {
                _distributeRewardOfQuestion(game, qIndexes[i], distributer);
            }
        }

        if (race.gamesCompleted[distributer].length == 0) {
            race.gamesCompleted[distributer] = new uint256[](0);
        }
        
        race.gamesCompleted[distributer].push(gameIndex);
    }

    function _distributeRewardOfQuestion(
        Game storage game,
        uint8 questionIndex,
        address actualSender
    ) internal {
        Question storage question = game.questions[questionIndex];
        uint8 minAnswerId = _getWinningAnswerIdOfQuestion(question);
        for (
            uint256 j = 0;
            j < question.playersByAnswer[minAnswerId].length;
            j++
        ) {
            address winner = question.playersByAnswer[minAnswerId][j];
            if (winner == actualSender) {
                game.scoreByAddress[winner] += 1;
                // * question.playersByAnswer[minAnswerId].length;
            }
        }
    }

    function _getWinningAnswerIdOfQuestion(
        Question storage question
    ) internal view returns (uint8 winningAnswerId) {
        if (question.distributed) revert AlreadyDistributed();
        uint256 minCount = type(uint256).max;
        winningAnswerId = 0;

        for (uint8 i = 0; i < questions[question.questionId].answers.length; i++) {
            uint256 count = question.playersByAnswer[i].length;

            if (count < minCount) {
                minCount = count;
                winningAnswerId = i;
            }
        }
    }

    function validateRaceId(uint256 raceId) internal view {
        if (raceId >= nextRaceId) revert InvalidRaceId();
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
        uint64 hoursBeforeFinish,
        uint8 numOfPlayersRequired,
        GameParams[] memory games
    ) external {
        if (userHasAdminAccess[msg.sender] == false && msg.sender != owner()) {
            revert AccessDenied();
        }
        uint64 startAt = uint64(block.timestamp + (hoursBeforeFinish * 3600));
        if (startAt < block.timestamp + MIN_SECONDS_BEFORE_START_RACE)
            revert InvalidTimestamp();
        if (games.length == 0) revert EmptyQuestions();
        Race storage _race = races[nextRaceId];
        _race.name = name;
        _race.numOfPlayersRequired = numOfPlayersRequired;
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
        uint256 raceId,
        uint256 gameId
    ) public view returns (QuestionInfoReturnType[] memory) {
        uint256 length = races[raceId].games[gameId].numOfQuestions;

        // Initialize an array to store QuestionInfoReturnType structs
        QuestionInfoReturnType[] memory questionsInfo = new QuestionInfoReturnType[](length);

        // Populate the questionsInfo array
        for (uint8 i = 0; i < length; i++) {
            uint256 questionId = races[raceId].games[gameId].questions[i].questionId;
            questionsInfo[i] = QuestionInfoReturnType({
                id: questionId,
                info: questions[questionId]
            });
        }

        // Return the populated questionsInfo array
        return questionsInfo;
    }


    function getGameNames(uint256 id) public view returns (string memory) {
        return gameNames[id];
    }

    function getRaces(
        uint256 id,
        address user
    )
        public
        view
        returns (
            string memory name,
            uint64 startAt,
            uint8 numOfGames,
            uint8 numOfQuestions,
            uint256[] memory games,
            uint256[] memory gamesCompletedPerUser,
            uint256 raceDuration,
            bool refunded,
            address[] memory registeredUsers,
            RabbitTunnel memory rabbitTunnel,
            uint8 numOfPlayersRequired
        )
    {
        Race storage race = races[id];
        name = race.name;
        startAt = race.startAt;
        numOfGames = race.numOfGames;
        numOfQuestions = race.numOfQuestions;

        // Initialize an array to store gameIds
        games = new uint256[](race.numOfGames);
        
        // Populate the games array with gameIds
        for (uint8 i = 0; i < race.numOfGames; i++) {
            games[i] = race.games[i].gameId;
        }

        // populate gamesCompleted per race
        gamesCompletedPerUser = race.gamesCompleted[user];

        raceDuration = GAME_DURATION * race.numOfGames;

        refunded = race.refunded[user];

        registeredUsers = race.registeredUsers;

        rabbitTunnel = race.rabbitTunnel;

        numOfPlayersRequired = race.numOfPlayersRequired;
    }

    function getScoreAtGameOfUser(
        uint256 raceId,
        uint256 gameIndex,
        address user,
        string memory gameName
    ) external view returns (uint256) {
        if (keccak256(abi.encodePacked(gameName)) == keccak256(abi.encodePacked("underdog"))) {
            return races[raceId].games[gameIndex].scoreByAddress[user];
        } 

        if (keccak256(abi.encodePacked(gameName)) == keccak256(abi.encodePacked("rabbit-hole"))) {
            uint256 points = 0;
            for (uint256 i = 0; i < races[raceId].rabbitTunnel.pointsAddresses.length; i++) {
                if (races[raceId].rabbitTunnel.pointsAddresses[i] == user) {
                    points = races[raceId].rabbitTunnel.pointsAmount[i];
                }
            }
            return points;
        }

        if (keccak256(abi.encodePacked(gameName)) == keccak256(abi.encodePacked("bullrun"))) {
            (address user1, address user2, address user3) = BULLRUN.getWinnersPerGame(raceId);

            if (user1 == msg.sender) return 3;
            if (user2 == msg.sender) return 2;
            if (user3 == msg.sender) return 1;
        }

        return 0;
    }

    function getScoreAtRaceOfUser(uint256 raceId, address user) external view returns (uint256) {
        uint256 scores = 0;
        Race storage race = races[raceId];
        
        for (uint256 gameId = 0; gameId < race.numOfGames; gameId++) {
            Game storage game = race.games[gameId];
            scores += game.scoreByAddress[user];
        }

        uint256 pointsRabbitTunnel = 0;
        for (uint256 i = 0; i < races[raceId].rabbitTunnel.pointsAddresses.length; i++) {
            if (races[raceId].rabbitTunnel.pointsAddresses[i] == user) {
                pointsRabbitTunnel = races[raceId].rabbitTunnel.pointsAmount[i];
            }
        }

        scores += pointsRabbitTunnel;

        return scores;
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
            _races[index].registered = race.playerRegistered[user];

            // Initialize an array to store gameIds
            uint256[] memory games = new uint256[](race.numOfGames);
            
            // Populate the games array with gameIds
            for (uint8 i = 0; i < race.numOfGames; i++) {
                games[i] = race.games[i].gameId;
            }
            _races[index].games = games;

            _races[index].gamesCompletedPerUser = race.gamesCompleted[user];

            _races[index].raceDuration = GAME_DURATION * race.numOfGames;

            _races[index].refunded = race.refunded[user];

            _races[index].registeredUsers = race.registeredUsers;

            _races[index].rabbitTunnel = race.rabbitTunnel;

            _races[index].numOfPlayersRequired = race.numOfPlayersRequired;
        }

        return _races;
    }

    function getRaceStatus(uint256 raceId) external view returns (RaceStatus) {
        if (raceId > nextRaceId) return RaceStatus.NON_EXIST;
        Race storage race = races[raceId];
        if (race.startAt < block.timestamp) return RaceStatus.CREATED;
        if (race.registeredUsers.length < NUM_OF_PLAYERS_PER_RACE)
            return RaceStatus.CANCELLED;

        return RaceStatus.STARTED;
    }


    // BULLRUN FUNCTIONS
    function BULLRUN_setPointsPerPerksForRace(uint256 raceId, string[] calldata perks, uint256[] calldata points) public onlyOwner {
        validateRaceId(raceId);
        BULLRUN.setPointsPerPerksForRace(raceId, perks, points);
    }

    function BULLRUN_makeChoice(uint256 raceId, string calldata choice, uint256 points) public {
        validateRaceId(raceId);
        BULLRUN.makeChoice(raceId, choice, points);
    }

    function BULLRUN_getAmountOfPointsPerGame(address user, uint256 raceId) public view returns(uint256 points) {
        validateRaceId(raceId);
        return BULLRUN.getAmountOfPointsPerGame(user, raceId);
    }
}