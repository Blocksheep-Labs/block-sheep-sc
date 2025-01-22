// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract BlockSheep is Ownable {
    using SafeERC20 for IERC20;

    uint64 private constant MIN_SECONDS_BEFORE_START_RACE = 5 minutes;

    IERC20 public immutable UNDERLYING;
    uint256 public immutable COST;

    mapping(address => uint256) public balances;

    mapping(uint256 => Race) private races;

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
        uint256 id;
        uint64 startAt;
        mapping(address => bool) playerRegistered;
        mapping(address => bool) refunded;
        address[] registeredUsers;
        uint8 numOfPlayersRequired;
    }

    struct RaceInfo {
        uint256 id;
        uint64 startAt;
        bool registered;
        RaceStatus status;
        bool refunded;
        address[] registeredUsers;
        uint8 numOfPlayersRequired;
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
        require(balances[msg.sender] > amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        UNDERLYING.safeTransfer(msg.sender, amount);
    }

    function refundBalance(uint256 amount, uint256 raceId) external {
        Race storage race = races[raceId];
        require(race.startAt < block.timestamp, "Invalid timestamp");
        require(race.playerRegistered[msg.sender] == true, "Not registered");

        balances[msg.sender] += amount;
        race.refunded[msg.sender] = true;
    }

    function register(uint256 raceId) external {
        Race storage race = races[raceId];
        require(raceId < nextRaceId, "Invalid race ID");
        require(block.timestamp < race.startAt, "Invalid timestamp");
        require(race.playerRegistered[msg.sender] == false, "Already registered");
        require(race.registeredUsers.length < race.numOfPlayersRequired, "Race is full");
        
        balances[msg.sender] -= COST;
        race.playerRegistered[msg.sender] = true;
        race.registeredUsers.push(msg.sender);

        // emit Registered(msg.sender, race.numOfQuestions * COST);
        emit Registered(msg.sender, 0);
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


    function callFunctionAtRegisteredContract (
        string memory contractName,
        bytes memory data
    ) public returns (bytes memory) {
        address target = targetContracts[contractName];
        require(target != address(0), "Target was not found");

        (bool success, bytes memory returnData) = target.call(data);
        require(success, "Call failed");

        return returnData;
    }

    /// Admin functions
    function addRace(
        uint64 hoursBeforeFinish,
        uint8 numOfPlayersRequired,
        bytes calldata initStateForBullrun, //int256[3][3] calldata points,
        bytes calldata initStateForUnderdog //QuestionInfo[] calldata questions
    ) external {
        require(userHasAdminAccess[msg.sender] == true || msg.sender == owner(), "Access denied");
        
        uint64 startAt = uint64(block.timestamp + (hoursBeforeFinish * 3600));
        require(startAt > block.timestamp + MIN_SECONDS_BEFORE_START_RACE, "Invalid timestamp");

        Race storage _race = races[nextRaceId];
        _race.id = nextRaceId;
        _race.numOfPlayersRequired = numOfPlayersRequired;
        _race.startAt = startAt;

        // init underdog
        bytes memory underdogData = abi.encodeWithSelector(
            bytes4(keccak256("initRace(uint256,bytes)")),
            nextRaceId,
            initStateForUnderdog
        );
        callFunctionAtRegisteredContract("UNDERDOG", underdogData);

        // init bullrun
        bytes memory bullrunData = abi.encodeWithSelector(
            bytes4(keccak256("initRace(uint256,bytes)")),
            nextRaceId,
            initStateForBullrun
        );
        callFunctionAtRegisteredContract("BULLRUN", bullrunData);

        // init rabbithole
        // RABBITHOLE DOES NOT REQUIRE TO CALL THE initRace FUNCTION

        nextRaceId++;
    }


    function getRaceStatus(uint256 raceId) public view returns (RaceStatus) {
        if (raceId > nextRaceId) return RaceStatus.NON_EXIST;
        Race storage race = races[raceId];
        if (race.startAt < block.timestamp) return RaceStatus.CREATED;
        //if (race.registeredUsers.length < NUM_OF_PLAYERS_PER_RACE)
        //    return RaceStatus.CANCELLED;

        return RaceStatus.STARTED;
    }


    function getRace(uint256 id, address user) public view returns (RaceInfo memory raceInfo) {
        Race storage race = races[id];

        raceInfo.id = race.id;

        raceInfo.startAt = race.startAt;
        
        raceInfo.registered = race.playerRegistered[user];

        raceInfo.refunded = race.refunded[user];

        raceInfo.registeredUsers = race.registeredUsers;

        raceInfo.numOfPlayersRequired = race.numOfPlayersRequired;

        raceInfo.status = getRaceStatus(id);
    }


    function getScoreAtRaceOfUser(
        uint256 raceId, 
        address user
    ) external view returns (uint256) {
        
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

            _races[index].startAt = race.startAt;
            
            _races[index].registered = race.playerRegistered[user];

            _races[index].refunded = race.refunded[user];

            _races[index].registeredUsers = race.registeredUsers;

            _races[index].numOfPlayersRequired = race.numOfPlayersRequired;

            _races[index].status = getRaceStatus(race.id);
        }

        return _races;
    }
}