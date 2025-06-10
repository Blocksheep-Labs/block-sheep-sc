// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGameInterface } from "./IGameInterface.sol";


contract BlockSheep is Ownable {
    using SafeERC20 for IERC20;

    int256 private constant BPS = 1000;
    uint64 private constant MIN_SECONDS_BEFORE_START_RACE = 5 minutes;

    mapping(address => uint256) public balances;

    mapping(uint256 => Race) public races;

    uint256 public nextRaceId;

    // list of admin access
    mapping(address => bool) public userHasAdminAccess;

    mapping(string => address) public targetContracts;

    // users who bought race entry
    mapping(uint256 => mapping(address => bool)) public payedRaceEntries;

    // raceId      // event (game, other stuff)   // user    // negative points
    mapping(uint256 => mapping(string => mapping(address => int256))) public raceUpdateBonusMalusPoints;
    mapping(uint256 => mapping(string => mapping(address => bool))) public raceUpdateBonusMalusPointsOfUser;
    mapping(uint256 => mapping(string => bool)) public raceUpdateBonusMalusPointsEnabled;


    enum RaceStatus {
        NON_EXIST,
        CREATED,
        STARTED,
        CANCELLED,
        DISRIBUTTED
    }

    struct Race {
        uint8 entryPrice;
        uint8 storyKey;
        uint8 numOfPlayersRequired;
        uint64 endAt;
        uint256 id;
        mapping(address => bool) playerRegistered;
        mapping(address => bool) refunded;
        string[] screens;
        address[] registeredUsers;
    }

    struct RaceInfo {
        bool refunded;
        bool registered;
        uint8 entryPrice;
        uint8 storyKey;
        uint8 numOfPlayersRequired;
        uint64 endAt;
        uint256 id;
        string[] screens;
        address[] registeredUsers;
        RaceStatus status;
    }

    event Registered(address user, uint256 amount);
    event Deposited(address user, uint256 amount, uint256 balance);
    event Withdrawed(address user, uint256 amount, uint256 balance);

    constructor(
        address owner
    ) Ownable(owner) {
        userHasAdminAccess[owner] = true;
    }

    function deposit(uint256 amount, address user) external onlyOwner {
        require(amount > 0, "Amount to buy must be greater than zero");
        balances[user] += amount;

        emit Deposited(user, amount, balances[user]);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;

        emit Withdrawed(msg.sender, amount, balances[msg.sender]);
    }


    function refundWinningBalance(uint256 raceId) external {
        Race storage race = races[raceId];
        require(race.endAt < block.timestamp, "Race is not finished");
        require(race.playerRegistered[msg.sender], "Not registered");
        require(!race.refunded[msg.sender], "Already refunded");

        RaceInfo memory raceInfoById = getRace(raceId, msg.sender);
        address[] memory users = raceInfoById.registeredUsers;
        uint256 userCount = users.length;
        require(userCount > 1, "Not enough users in race");

        // Gather user + score pairs
        address[] memory sortedUsers = new address[](userCount);
        int256[] memory scores = new int256[](userCount);
        for (uint256 i = 0; i < userCount; i++) {
            sortedUsers[i] = users[i];
            scores[i] = getScoreAtRaceOfUser(raceId, users[i]);
        }

        // Sort by score descending using simple bubble sort (for clarity)
        for (uint256 i = 0; i < userCount - 1; i++) {
            for (uint256 j = i + 1; j < userCount; j++) {
                if (scores[j] > scores[i]) {
                    // Swap scores
                    int256 tempScore = scores[i];
                    scores[i] = scores[j];
                    scores[j] = tempScore;

                    // Swap users to keep alignment
                    address tempUser = sortedUsers[i];
                    sortedUsers[i] = sortedUsers[j];
                    sortedUsers[j] = tempUser;
                }
            }
        }

        // Determine position of msg.sender
        uint256 rank = userCount;
        int256 userScore = 0;
        for (uint256 i = 0; i < userCount; i++) {
            if (sortedUsers[i] == msg.sender) {
                rank = i;
                userScore = scores[i];
                break;
            }
        }

        require(userScore > 0, "No refund for 0 points");

        uint256 topK = userCount / 2;
        require(rank < topK, "Only top half get refund");

        // Calculate bonus, linear decay from COST to 0 across topK ranks
        uint256 bonus = 0;
        if (topK > 1) {
            bonus = race.entryPrice * (topK - rank) / (topK - 1); // full bonus at top, 0 at lowest eligible
        } else {
            bonus = race.entryPrice; // edge case: only 1 top user
        }

        uint256 refundAmount = race.entryPrice + bonus;
        balances[msg.sender] += refundAmount;
        race.refunded[msg.sender] = true;
    }



    function register(uint256 raceId, address user) external {
        require(userHasAdminAccess[msg.sender] == true || msg.sender == owner(), "Access denied");

        Race storage race = races[raceId];
        require(raceId < nextRaceId, "Invalid race ID");
        require(block.timestamp < race.endAt, "Race is finished");
        require(race.playerRegistered[user] == false, "Already registered");
        require(race.registeredUsers.length < race.numOfPlayersRequired, "Race is full");
        require(balances[user] >= race.entryPrice, "Not enough balance");

        balances[user] -= race.entryPrice;
        race.playerRegistered[user] = true;
        race.registeredUsers.push(user);

        emit Registered(user, race.entryPrice);
    }

    function setAdminRights(address user, bool isAdmin) external onlyOwner {
        userHasAdminAccess[user] = isAdmin;
    }

    function validateRaceId(uint256 raceId) public view {
        require(raceId < nextRaceId, "Invalid race ID");
    }

    // Set the address for a specific contract
    function registerContract(string memory name, address contractAddress) external {
        targetContracts[name] = contractAddress;
    }

    /// Admin functions
    function addRace(
        uint8 entryPrice,
        uint64 hoursBeforeFinish,
        uint8 numOfPlayersRequired,
        uint8 storyKey,
        string[] memory screens,
        bytes calldata initStateForBullrun, //int256[3][3] calldata points,
        bytes calldata initStateForUnderdog //QuestionInfo[] calldata questions
    ) external {
        require(userHasAdminAccess[msg.sender] == true || msg.sender == owner(), "Access denied");

        uint64 endAt = uint64(block.timestamp + (hoursBeforeFinish * 1 hours));
        require(endAt > block.timestamp + MIN_SECONDS_BEFORE_START_RACE, "Invalid timestamp");

        Race storage _race = races[nextRaceId];
        _race.entryPrice = entryPrice;
        _race.id = nextRaceId;
        _race.numOfPlayersRequired = numOfPlayersRequired;
        _race.endAt = endAt;
        _race.screens = screens;
        _race.storyKey = storyKey;

        for (uint256 i = 0; i < screens.length; i++) {
            // init underdog
            if (keccak256(bytes(screens[i])) == keccak256(bytes("UNDERDOG"))) {
                initRace("UNDERDOG", nextRaceId, initStateForUnderdog);
            }

            // init bullrun
            if (keccak256(bytes(screens[i])) == keccak256(bytes("BULLRUN"))) {
                initRace("BULLRUN", nextRaceId, initStateForBullrun);
            }

            // init rabbithole
            // RABBITHOLE DOES NOT REQUIRE TO CALL THE initRace FUNCTION
        }

        nextRaceId++;
    }


    function getRaceStatus(uint256 raceId) public view returns (RaceStatus) {
        if (raceId > nextRaceId) return RaceStatus.NON_EXIST;
        Race storage race = races[raceId];
        if (race.endAt < block.timestamp) return RaceStatus.CREATED;
        //if (race.registeredUsers.length < NUM_OF_PLAYERS_PER_RACE)
        //    return RaceStatus.CANCELLED;

        return RaceStatus.STARTED;
    }


    function getRace(uint256 id, address user) public view returns (RaceInfo memory raceInfo) {
        Race storage race = races[id];

        raceInfo.entryPrice = race.entryPrice;

        raceInfo.id = race.id;

        raceInfo.endAt = race.endAt;

        raceInfo.registered = race.playerRegistered[user];

        raceInfo.refunded = race.refunded[user];

        raceInfo.registeredUsers = race.registeredUsers;

        raceInfo.numOfPlayersRequired = race.numOfPlayersRequired;

        raceInfo.status = getRaceStatus(id);

        raceInfo.screens = race.screens;

        raceInfo.storyKey = race.storyKey;
    }


    function getScoreAtRaceOfUser(
        uint256 raceId,
        address user
    ) public view returns (int256) {
        Race storage race = races[raceId];
        int256 score = 0;

        // Loop through all screen names dynamically
        for (uint256 i = 0; i < race.screens.length; i++) {
            string memory screen = race.screens[i];

            // 1. Base points: {SCREEN}, but it has to be registered as a game contract
            if (targetContracts[screen] != address(0)) {
                score += getPoints(screen, user, raceId);
            }

            // 2. Sprint bonus: SPRINT_{SCREEN}
            string memory sprintKey = string(abi.encodePacked("SPRINT_", screen));
            if (raceUpdateBonusMalusPointsEnabled[raceId][sprintKey]) {
                score += raceUpdateBonusMalusPoints[raceId][sprintKey][user];
            }

            // 3. Obstacle malus: OBSTACLE_{SCREEN}
            string memory obstacleKey = string(abi.encodePacked("OBSTACLE_", screen));
            if (raceUpdateBonusMalusPointsEnabled[raceId][obstacleKey]) {
                int256 value = raceUpdateBonusMalusPoints[raceId][obstacleKey][user];
                if (value != 1 * BPS) {
                    score -= 1 * BPS;
                }
            }

            // 4. Change tyres penalty: CHANGE_TYRES_{SCREEN}
            string memory tyresKey = string(abi.encodePacked("CHANGE_TYRES_", screen));
            if (raceUpdateBonusMalusPointsEnabled[raceId][tyresKey]) {
                score -= raceUpdateBonusMalusPoints[raceId][tyresKey][user];
            }

            // 5. Bonuses from mini-games like "steering wheel in underdog"
            string memory bonusKey = string(abi.encodePacked("BONUS_", screen));
            if (raceUpdateBonusMalusPointsEnabled[raceId][bonusKey]) {
                score += raceUpdateBonusMalusPoints[raceId][bonusKey][user];
            }
        }

        // Add race start points (not tied to screen)
        if (raceUpdateBonusMalusPointsEnabled[raceId]["RACE_START"]) {
            score += raceUpdateBonusMalusPoints[raceId]["RACE_START"][user];
        }

        return score;
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

            _races[index].entryPrice = race.entryPrice;

            _races[index].id = race.id;

            _races[index].endAt = race.endAt;

            _races[index].registered = race.playerRegistered[user];

            _races[index].refunded = race.refunded[user];

            _races[index].registeredUsers = race.registeredUsers;

            _races[index].numOfPlayersRequired = race.numOfPlayersRequired;

            _races[index].status = getRaceStatus(race.id);

            _races[index].screens = race.screens;

            _races[index].storyKey = race.storyKey;
        }

        return _races;
    }

    // Function to check if a player is registered for a specific race
    function isPlayerRegistered(uint256 raceId, address player) public view returns (bool) {
        return races[raceId].playerRegistered[player];
    }



    function getPoints(string memory gameName, address user, uint256 raceId) public view returns (int256) {
        return IGameInterface(targetContracts[gameName]).getPoints(user, raceId);
    }

    function getInternalScore(string memory gameName, address user, uint256 raceId) public view returns (int256) {
        return IGameInterface(targetContracts[gameName]).getInternalScore(user, raceId);
    }

    function getUserChoices(string memory gameName, uint256 raceId, address user) public view returns (uint256[] memory) {
        return IGameInterface(targetContracts[gameName]).getUserChoices(raceId, user);
    }

    function getWinner(string memory gameName, uint256 raceId) public view returns (address[] memory, int256[] memory) {
        return IGameInterface(targetContracts[gameName]).getWinner(raceId);
    }

    function getRules(string memory gameName, uint256 raceId) public view returns (bytes memory) {
        return IGameInterface(targetContracts[gameName]).getRules(raceId);
    }

    function makeMove(string memory gameName, uint256 raceId, bytes memory data) public {
        IGameInterface(targetContracts[gameName]).makeMove(raceId, data);
    }

    function distribute(string memory gameName, uint256 raceId, bytes memory data) public {
        IGameInterface(targetContracts[gameName]).distribute(raceId, data);
    }

    function initRace(string memory gameName, uint256 raceId, bytes memory data) public {
        IGameInterface(targetContracts[gameName]).initRace(raceId, data);
    }


    function changeTyres(string memory raceUpdateScreen, string memory nextGameScreen, uint256 raceId) public {
        string memory event_name = string(abi.encodePacked("CHANGE_TYRES_", raceUpdateScreen));
        require(raceUpdateBonusMalusPointsOfUser[raceId][event_name][msg.sender] == false, "Already passed");

        raceUpdateBonusMalusPoints[raceId][event_name][msg.sender] = 2 * BPS;
        raceUpdateBonusMalusPointsOfUser[raceId][event_name][msg.sender] = true;
        raceUpdateBonusMalusPointsEnabled[raceId][event_name] = true;
        IGameInterface(targetContracts[nextGameScreen]).changeTyres(raceId, msg.sender);
    }

    function jumpAnObstacle(string memory raceUpdateScreen, uint256 raceId) public {
        string memory event_name = string(abi.encodePacked("OBSTACLE_", raceUpdateScreen));
        require(raceUpdateBonusMalusPointsOfUser[raceId][event_name][msg.sender] == false, "Already passed");

        raceUpdateBonusMalusPoints[raceId][event_name][msg.sender] = 1 * BPS;
        raceUpdateBonusMalusPointsOfUser[raceId][event_name][msg.sender] = true;
        raceUpdateBonusMalusPointsEnabled[raceId][event_name] = true;
    }

    function sprint(string memory raceUpdateScreen, uint256 raceId) public {
        string memory event_name = string(abi.encodePacked("SPRINT_", raceUpdateScreen));
        require(raceUpdateBonusMalusPointsOfUser[raceId][event_name][msg.sender] == false, "Already passed");

        raceUpdateBonusMalusPoints[raceId][event_name][msg.sender] = 3 * BPS;
        raceUpdateBonusMalusPointsOfUser[raceId][event_name][msg.sender] = true;
        raceUpdateBonusMalusPointsEnabled[raceId][event_name] = true;
    }

    function beginRace(uint256 raceId, int256 points) external {
        string memory event_name = "RACE_START";
        require(raceUpdateBonusMalusPointsOfUser[raceId][event_name][msg.sender] == false, "Already passed");

        raceUpdateBonusMalusPoints[raceId][event_name][msg.sender] = points * BPS;
        raceUpdateBonusMalusPointsOfUser[raceId][event_name][msg.sender] = true;
        raceUpdateBonusMalusPointsEnabled[raceId][event_name] = true;
    }

    function saveBonus(uint256 raceId, int256 pointsWithBPS, string memory gameScreen) external {
        string memory event_name = string(abi.encodePacked("BONUS_", gameScreen));

        require(raceUpdateBonusMalusPointsOfUser[raceId][event_name][msg.sender] == false, "Already passed");

        raceUpdateBonusMalusPoints[raceId][event_name][msg.sender] = pointsWithBPS;
        raceUpdateBonusMalusPointsOfUser[raceId][event_name][msg.sender] = true;
        raceUpdateBonusMalusPointsEnabled[raceId][event_name] = true;
    }


    function staticCallAnyGameFunction(
        string memory gameName,
        bytes memory functionSignature
    ) public view returns (bytes memory) {
        address target = targetContracts[gameName];
        require(target != address(0), "Game not found");

        (bool success, bytes memory result) = target.staticcall(functionSignature);
        require(success, "Static call failed");

        return result;
    }
}
