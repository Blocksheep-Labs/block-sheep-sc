// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGameInterface } from "./IGameInterface.sol";


contract BlockSheep is Ownable {
    using SafeERC20 for IERC20;

    uint64 private constant MIN_SECONDS_BEFORE_START_RACE = 5 minutes;

    IERC20 public immutable UNDERLYING;
    uint256 public immutable COST;

    mapping(address => uint256) public balances;

    mapping(uint256 => Race) public races;

    uint256 public nextRaceId;

    // list of admin access
    mapping(address => bool) public userHasAdminAccess;

    mapping(string => address) public targetContracts;

    enum RaceStatus {
        NON_EXIST,
        CREATED,
        STARTED,
        CANCELLED,
        DISRIBUTTED
    }

    struct Race {
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
        uint8 storyKey;
        uint8 numOfPlayersRequired;
        uint64 endAt;
        uint256 id;
        string[] screens;
        address[] registeredUsers;
        RaceStatus status;
    }

    event Registered(address user, uint256 amount);

    constructor(
        address _underlying,
        address owner,
        uint256 _cost
    ) Ownable(owner) {
        UNDERLYING = IERC20(_underlying);
        COST = _cost;
        userHasAdminAccess[owner] = true;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount to buy must be greater than zero");

        UNDERLYING.safeTransferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        UNDERLYING.safeTransfer(msg.sender, amount);
    }

    function refundBalance(uint256 amount, uint256 raceId) external {
        Race storage race = races[raceId];
        require(race.endAt < block.timestamp, "Race is not finished");
        require(race.playerRegistered[msg.sender] == true, "Not registered");
        require(race.refunded[msg.sender] == false, "Already refunded");


        balances[msg.sender] += amount;
        race.refunded[msg.sender] = true;
    }

    function refundWinningBalance(uint256 raceId) external {
        Race storage race = races[raceId];
        require(race.endAt < block.timestamp, "Race is not finished");
        require(race.playerRegistered[msg.sender], "Not registered");
        require(!race.refunded[msg.sender], "Already refunded");

        RaceInfo memory raceInfoById = getRace(raceId, msg.sender);
        
        uint256 userCount = raceInfoById.registeredUsers.length;
        require(userCount > 0, "No users in race");

        address[] memory users = new address[](userCount);
        int256[] memory points = new int256[](userCount);
        
        // Fill users and points arrays
        for (uint256 i = 0; i < userCount; i++) {
            users[i] = raceInfoById.registeredUsers[i];
            points[i] = getScoreAtRaceOfUser(raceId, users[i]);
        }

        // Determine msg.sender's position in the race
        uint256 position = userCount;
        for (uint256 i = 0; i < userCount; i++) {
            if (users[i] == msg.sender) {
                position = i;
                break;
            }
        }

        require(position < userCount, "User not found in race");

        // Calculate bonus based on position (example: higher rank gets more bonus)
        uint256 bonus = (userCount - position) * 10**18;

        uint256 amount = COST + bonus;

        balances[msg.sender] += amount;
        race.refunded[msg.sender] = true;
    }


    function register(uint256 raceId) external {
        Race storage race = races[raceId];
        require(raceId < nextRaceId, "Invalid race ID");
        require(block.timestamp < race.endAt, "Race is not finished");
        require(race.playerRegistered[msg.sender] == false, "Already registered");
        require(race.registeredUsers.length < race.numOfPlayersRequired, "Race is full");
        require(balances[msg.sender] >= COST, "Not enough balance");
        
        balances[msg.sender] -= COST;
        race.playerRegistered[msg.sender] = true;
        race.registeredUsers.push(msg.sender);

        emit Registered(msg.sender, COST);
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
        int256 score = 0;

        score += getPoints("UNDERDOG", user, raceId);

        score += getPoints("RABBITHOLE", user, raceId);

        score += getPoints("BULLRUN", user, raceId);

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

    function initRace(string memory gameName, uint256 raceid, bytes memory data) public {
        IGameInterface(targetContracts[gameName]).initRace(raceid, data);
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
