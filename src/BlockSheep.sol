// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { GAME_Bullrun } from "./GAME_Bullrun.sol";
import { GAME_RabbitHole } from "./GAME_RabbitHole.sol";
import { GAME_Underdog } from "./GAME_Underdog.sol";

contract BlockSheep is Ownable, GAME_Bullrun, GAME_RabbitHole, GAME_Underdog {
    using SafeERC20 for IERC20;

    uint8 private constant NUM_OF_PLAYERS_PER_RACE = 3;
    uint64 private constant MIN_SECONDS_BEFORE_START_RACE = 5 minutes;
    uint64 private constant GAME_DURATION = 5 * 60;

    IERC20 public immutable UNDERLYING;
    uint256 public immutable COST;

    mapping(address => uint256) public balances;
    uint256 public feeCollected;

    uint256 private nextQuestionId;

    uint256 private nextGameNameId;

    mapping(uint256 => Race) private races;

    uint256 public nextRaceId;

    // list of admin access
    mapping(address => bool) public userHasAdminAccess;

    enum RaceStatus {
        NON_EXIST,
        CREATED,
        STARTED,
        CANCELLED,
        DISRIBUTTED
    }

    struct Race {
        uint64 startAt;
        mapping(address => bool) playerRegistered;
        mapping(address => bool) refunded;
        address[] registeredUsers;
        uint8 numOfPlayersRequired;
    }

    struct RaceInfo {
        uint64 startAt;
        bool registered;
        RaceStatus status;
        uint256[] games;
        uint256[] gamesCompletedPerUser;
        uint256 raceDuration;
        bool refunded;
        address[] registeredUsers;
        uint8 numOfPlayersRequired;
    }


    error InvalidTimestamp();
    error EmptyQuestions();
    error InvalidRaceId();
    error InvalidGameIndex();
    error LengthMismatch();
    error Timeout();
    error AlreadyDistributed();
    error AlreadyRegistered();
    error RaceIsFull();
    error NotRegistered();
    error AccessDenied();
    error GameIsNotComplted();

    event Registered(address user, uint256 amount);

    constructor(
        address _underlying,
        address owner,
        uint256 _cost
    ) Ownable(owner) GAME_Bullrun(address(this)) GAME_RabbitHole(address(this)) GAME_Underdog(address(this)) {
        UNDERLYING = IERC20(_underlying);
        COST = _cost;
        userHasAdminAccess[owner] = true;
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
        
        // balances[msg.sender] -= race.numOfQuestions * COST;
        race.playerRegistered[msg.sender] = true;
        race.registeredUsers.push(msg.sender);

        // emit Registered(msg.sender, race.numOfQuestions * COST);
        emit Registered(msg.sender, 0);
    }

    function setAdminRights(address user, bool isAdmin) external onlyOwner {
        userHasAdminAccess[user] = isAdmin;
    }

    function validateRaceId(uint256 raceId) public view {
        if (raceId >= nextRaceId) revert InvalidRaceId();
    }

    function validateGameCompletion(uint256 raceId, string calldata gameName) public view {
        validateRaceId(raceId);
        if (keccak256(abi.encodePacked(gameName)) == keccak256(abi.encodePacked("underdog"))) {
            // TODO: check for underdog game completion somehow (after the refactoring of the underdog game)
        }
        // check the rabbit-hole game to be completed
        if (keccak256(abi.encodePacked(gameName)) == keccak256(abi.encodePacked("rabbit-hole"))) {
            // if (races[raceId].rabbitTunnel.winner == address(0)) revert GameIsNotComplted();
        }
    }

    /// Admin functions
    function addRace(
        uint64 hoursBeforeFinish,
        uint8 numOfPlayersRequired,
        int256[3][3] calldata points,
        QuestionInfo[] calldata questions
    ) external {
        if (userHasAdminAccess[msg.sender] == false && msg.sender != owner()) {
            revert AccessDenied();
        }
        uint64 startAt = uint64(block.timestamp + (hoursBeforeFinish * 3600));
        if (startAt < block.timestamp + MIN_SECONDS_BEFORE_START_RACE) revert InvalidTimestamp();

        Race storage _race = races[nextRaceId];
        _race.numOfPlayersRequired = numOfPlayersRequired;
        _race.startAt = startAt;

        BULLRUN_init(nextRaceId, points);
        UNDERDOG_init(nextRaceId, questions);

        nextRaceId++;
    }


    function getRaces(
        uint256 id,
        address user
    )
        public
        view
        returns (
            uint64 startAt,
            uint256 raceDuration,
            bool refunded,
            address[] memory registeredUsers,
            // RabbitTunnel memory rabbitTunnel,
            uint8 numOfPlayersRequired
        )
    {
        Race storage race = races[id];
        startAt = race.startAt;
        
        // Populate the games array with gameIds


        // populate gamesCompleted per race

        raceDuration = 1;

        refunded = race.refunded[user];

        registeredUsers = race.registeredUsers;

        // rabbitTunnel = race.rabbitTunnel;

        numOfPlayersRequired = race.numOfPlayersRequired;
    }

    function getScoreAtGameOfUser(
        uint256 raceId,
        uint256 gameIndex,
        address user,
        string memory gameName
    ) external view returns (uint256) {
        if (keccak256(abi.encodePacked(gameName)) == keccak256(abi.encodePacked("underdog"))) {
            // return races[raceId].games[gameIndex].scoreByAddress[user];
            return 0;
        } 

        if (keccak256(abi.encodePacked(gameName)) == keccak256(abi.encodePacked("rabbit-hole"))) {
            uint256 points = 0;
            /*
            for (uint256 i = 0; i < races[raceId].rabbitTunnel.pointsAddresses.length; i++) {
                if (races[raceId].rabbitTunnel.pointsAddresses[i] == user) {
                    points = races[raceId].rabbitTunnel.pointsAmount[i];
                }
            }
            */
            return points;
        }

        if (keccak256(abi.encodePacked(gameName)) == keccak256(abi.encodePacked("bullrun"))) {
            (address user1, address user2, address user3) = BULLRUN_getWinnersPerGame(raceId);

            if (user1 == msg.sender) return 3;
            if (user2 == msg.sender) return 2;
            if (user3 == msg.sender) return 1;
        }

        return 0;
    }

    function getScoreAtRaceOfUser(
        uint256 raceId, 
        address user
    ) external view returns (uint256) {
        uint256 scores = 0;
        // Race storage race = races[raceId];
        
        /*
        for (uint256 gameId = 0; gameId < race.numOfGames; gameId++) {
            Game storage game = race.games[gameId];
            scores += game.scoreByAddress[user];
        }
        */

        uint256 pointsRabbitTunnel = 0;
        /*
        for (uint256 i = 0; i < races[raceId].rabbitTunnel.pointsAddresses.length; i++) {
            if (races[raceId].rabbitTunnel.pointsAddresses[i] == user) {
                pointsRabbitTunnel = races[raceId].rabbitTunnel.pointsAmount[i];
            }
        }
        */

        scores += pointsRabbitTunnel;

        (address user1, address user2, address user3) = BULLRUN_getWinnersPerGame(raceId);
        if (user1 == user) scores += 3;
        if (user2 == user) scores += 2;
        if (user3 == user) scores += 1;

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
            _races[index].startAt = race.startAt;
            
            _races[index].registered = race.playerRegistered[user];

            
            // Populate the games array with gameIds

            //_races[index].raceDuration = GAME_DURATION * race.numOfGames;
            _races[index].raceDuration = 1;

            _races[index].refunded = race.refunded[user];

            _races[index].registeredUsers = race.registeredUsers;

            // _races[index].rabbitTunnel = race.rabbitTunnel;

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

}