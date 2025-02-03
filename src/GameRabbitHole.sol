// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import { IGameInterface } from "./IGameInterface.sol";

contract GameRabbitHole is IGameInterface {
    // user chioces by gameId
    //        raceId           roundId           user          fuelSubmitted
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) private RABBITHOLE_usersChoices;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) private RABBITHOLE_usersRemainingFuel;

    mapping(uint256 => mapping(address => int256)) private RABBITHOLE_points;

    // Track users who have participated in each game
    //      raceId            roundId      user-addrs
    mapping(uint256 => mapping(uint256 => address[])) private RABBITHOLE_roundParticipants;

    //        raceId           roundId           user         participated in?
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) private RABBITHOLE_roundWasParticipated;
    //        raceId           roundId     user
    mapping(uint256 => mapping(uint256 => address)) private RABBITHOLE_eliminatedAtRound;

    // track the distribution of the races by user
    mapping(uint256 => mapping(address => bool)) private RABBITHOLE_distributed;

    mapping(uint256 => address[]) private RABBITHOLE_winners;


    function getPoints(address user, uint256 raceId) public view returns (int256) {
        return RABBITHOLE_points[raceId][user];
    }

    function getUserChoices(uint256 raceId, address user) public view returns (uint256[] memory) {
        uint256 roundIndex = 0;

        // determine the maximum possible round index
        while (RABBITHOLE_eliminatedAtRound[raceId][roundIndex] != address(0)) {
            roundIndex++;
        }

        uint256[] memory fuelSubmissions = new uint256[](roundIndex);

        for (uint256 i = 0; i < roundIndex; i++) {
            fuelSubmissions[i] = RABBITHOLE_usersChoices[raceId][i][user];
        }

        return fuelSubmissions;
    }

    function getWinner(uint256 raceId) external view returns (address[] memory, int256[] memory) {
        require(RABBITHOLE_distributed[raceId][msg.sender], "Not distributed yet");
        int256[] memory points = new int256[](RABBITHOLE_winners[raceId].length);

        for (uint256 i = 0; i < RABBITHOLE_winners[raceId].length; i++) {
            points[i] = getPoints(RABBITHOLE_winners[raceId][i], raceId);
        }

        return (RABBITHOLE_winners[raceId], points);
    }

    function initRace(uint256 raceid, bytes memory data) external {
        // no need additional logic to init race
    }

    function makeMove(
        uint256 raceId,
        bytes memory data
    ) external {
        (uint256 fuelSubmission, uint256 fuelLeft, uint256 roundIndex) = abi.decode(data, (uint256, uint256, uint256));
        
        require(RABBITHOLE_roundWasParticipated[raceId][roundIndex][msg.sender] == false, "Already participated at round");

        // if was not participated at the round, mark as participated and store fuel data
        if (RABBITHOLE_roundWasParticipated[raceId][roundIndex][msg.sender] == false) {
            RABBITHOLE_roundParticipants[raceId][roundIndex].push(msg.sender);
            RABBITHOLE_usersChoices[raceId][roundIndex][msg.sender] = fuelSubmission;
            RABBITHOLE_usersRemainingFuel[raceId][roundIndex][msg.sender] = fuelLeft;
        }

        // mark user in round as participated
        RABBITHOLE_roundWasParticipated[raceId][roundIndex][msg.sender] = true;

        address eliminatedUser;
        uint256 minFuel = type(uint256).max;

        address[] memory participantsAtCurrentRound = RABBITHOLE_roundParticipants[raceId][roundIndex];

        // find the user with the lowest fuel (also comparing addresses)
        for (uint256 i = 0; i < participantsAtCurrentRound.length; i++) {
            address player = participantsAtCurrentRound[i];
            uint256 playerFuel = RABBITHOLE_usersChoices[raceId][roundIndex][player];

            if (
                playerFuel < minFuel ||
                (playerFuel == minFuel && player < eliminatedUser)
            ) {
                minFuel = playerFuel;
                eliminatedUser = player;
            }
        }

        // update eliminated user at the round
        RABBITHOLE_eliminatedAtRound[raceId][roundIndex] = eliminatedUser;
    }

    function distribute(
        uint256 raceId,
        bytes memory
    ) external {
        require(RABBITHOLE_eliminatedAtRound[raceId][0] != address(0), "RaceId does not exist or no eliminations");
        require(RABBITHOLE_distributed[raceId][msg.sender] == false, "Already distributed");

        uint256 roundIndex = 0;

        int256[] memory points = new int256[](3);
        points[0] = 3; // First place
        points[1] = 2; // Second place
        points[2] = 1; // Third place

        address[] memory topParticipants = new address[](3);

        // determine the maximum possible round index
        while (RABBITHOLE_eliminatedAtRound[raceId][roundIndex] != address(0)) {
            roundIndex++;
        }

        // search top players at the game
        for (uint256 rank = 0; rank < 3 && roundIndex > 0; rank++) {
            address eliminatedPlayer = RABBITHOLE_eliminatedAtRound[raceId][roundIndex - 1];

            if (rank == 0) {
                // winner - last non-eliminated player
                address[] memory participantsAtRound = RABBITHOLE_roundParticipants[raceId][roundIndex - 1];
                for (uint256 i = 0; i < participantsAtRound.length; i++) {
                    if (participantsAtRound[i] != eliminatedPlayer) {
                        topParticipants[rank] = participantsAtRound[i];
                        break;
                    }
                }
            } else {
                topParticipants[rank] = eliminatedPlayer;
            }

            // go to the next rank
            roundIndex--;
        }

        // allocate points to the list of top players
        for (uint256 i = 0; i < 3; i++) {
            if (topParticipants[i] != address(0)) {
                RABBITHOLE_points[raceId][topParticipants[i]] = points[i];
                RABBITHOLE_winners[raceId].push(topParticipants[i]);
            }
        }
        // set game as distributed
        RABBITHOLE_distributed[raceId][msg.sender] = true;
    }

    function getRules(uint256 raceId) external pure returns (bytes memory) {
        return abi.encode(raceId);
    }
}