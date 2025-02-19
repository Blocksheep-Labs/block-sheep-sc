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
    mapping(uint256 => mapping(uint256 => address[])) public RABBITHOLE_roundParticipants;

    //        raceId           roundId           user         participated in?
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) private RABBITHOLE_roundWasParticipated;
    //        raceId           roundId     user
    mapping(uint256 => mapping(uint256 => address)) public RABBITHOLE_eliminatedAtRound;

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
        (uint256 fuelSubmission, uint256 fuelLeft, uint256 roundIndex, address sender) = abi.decode(data, (uint256, uint256, uint256, address));
        
        require(RABBITHOLE_roundWasParticipated[raceId][roundIndex][sender] == false, "Already participated at round");

        // if was not participated at the round, mark as participated and store fuel data
        if (RABBITHOLE_roundWasParticipated[raceId][roundIndex][sender] == false) {
            RABBITHOLE_roundParticipants[raceId][roundIndex].push(sender);
            RABBITHOLE_usersChoices[raceId][roundIndex][sender] = fuelSubmission;
            RABBITHOLE_usersRemainingFuel[raceId][roundIndex][sender] = fuelLeft;
        }

        // mark user in round as participated
        RABBITHOLE_roundWasParticipated[raceId][roundIndex][sender] = true;

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
        bytes memory data
    ) external {
        (address sender) = abi.decode(data, (address));

        require(RABBITHOLE_eliminatedAtRound[raceId][0] != address(0), "RaceId does not exist or no eliminations");
        require(RABBITHOLE_distributed[raceId][sender] == false, "Already distributed");

        uint256 roundIndex = 0;

        // determine the maximum possible round index
        while (RABBITHOLE_eliminatedAtRound[raceId][roundIndex] != address(0)) {
            roundIndex++;
        }

        address[] memory participantsAtRound = RABBITHOLE_roundParticipants[raceId][roundIndex - 1];

        if (participantsAtRound.length == 2) {
            RABBITHOLE_points[raceId][sender] = 3;
            RABBITHOLE_winners[raceId].push(sender);
        }

        if (participantsAtRound.length == 1) {
            RABBITHOLE_points[raceId][sender] = 2;
            RABBITHOLE_winners[raceId].push(sender);
        }

        if (participantsAtRound.length == 0) {
            RABBITHOLE_points[raceId][sender] = 1;
            RABBITHOLE_winners[raceId].push(sender);
        }

        // set game as distributed
        RABBITHOLE_distributed[raceId][sender] = true;
    }

    function getRules(uint256 raceId) external pure returns (bytes memory) {
        return abi.encode(raceId);
    }
}