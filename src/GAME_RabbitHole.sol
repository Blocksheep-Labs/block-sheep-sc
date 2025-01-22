// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

contract GAME_RabbitHole {
    // user chioces by gameId
    //        raceId           roundId           user          fuelSubmitted
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public RABBITHOLE_usersChoices;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public RABBITHOLE_usersRemainingFuel;

    mapping(uint256 => mapping(address => uint256)) public RABBITHOLE_points;

    // Track users who have participated in each game
    //      raceId      user-addrs
    mapping(uint256 => mapping(uint256 => address[])) public RABBITHOLE_roundParticipants;

    //        raceId           roundId           user         participated in?
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public RABBITHOLE_roundWasParticipated;
    //        raceId           roundId     user
    mapping(uint256 => mapping(uint256 => address)) public RABBITHOLE_eliminatedAtRound;


    function getPoints(uint256 raceId) public view returns (uint256) {
        return RABBITHOLE_points[raceId][msg.sender];
    }

    function getUserChoices(uint256 raceId, uint256 roundIndex) public view returns (uint256) {
        return RABBITHOLE_usersChoices[raceId][roundIndex][msg.sender];
    }

    function makeMove(
        uint256 raceId,
        uint256 fuelSubmission,
        uint256 fuelLeft,
        uint256 roundIndex
    ) external {
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
        uint256 raceId
    ) external {
        require(RABBITHOLE_eliminatedAtRound[raceId][0] != address(0), "RaceId does not exist or no eliminations");

        uint256 roundIndex = 0;

        uint256[] memory points;
        points[0] = 3; // First place
        points[1] = 2; // Second place
        points[2] = 1; // Third place

        address[] memory topParticipants;

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
            }
        }
    }
}