// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GAME_Bullrun {
    // Struct to hold user choices and points
    struct BULLRUN_UserChoices {
        uint256[] selectedPerks;
        int256 points;
    }

    // user choices and points by raceId and user address
    //      raceId         user-addr    UserChoices
    mapping(uint256 => mapping(address => BULLRUN_UserChoices)) private BULLRUN_usersChoices;

    // points per perks per gameId
    //       raceId           perk-name   points
    mapping(uint256 => mapping(uint256 => int256[])) public BULLRUN_pointsPerPerks;

    // Track users who have participated in each game
    //      raceId      user-addrs
    mapping(uint256 => address[]) public BULLRUN_gameParticipants;

    constructor() {}

    function BULLRUN_getAmountOfPointsPerGame(address user, uint256 raceId) public view returns (int256) {
        return BULLRUN_usersChoices[raceId][user].points;
    }

    function BULLRUN_makeChoice(
        uint256 raceId, 
        uint256 perk1Index,
        uint256 perk2Index
    ) public {
        require(perk1Index < 3, "Invalid perk 1 index");
        require(perk2Index < 3, "Invalid perk 2 index");

        int256 points = BULLRUN_pointsPerPerks[raceId][perk1Index][perk2Index];

        BULLRUN_usersChoices[raceId][msg.sender].selectedPerks.push(perk1Index);
        BULLRUN_usersChoices[raceId][msg.sender].points += points;
    }

    function BULLRUN_setPointsPerPerksForRace(uint256 raceId, int256[3][3] calldata points) public {
        require(points.length > 0, "Points matrix cannot be empty");
        for (uint256 i = 0; i < points.length; i++) {
            BULLRUN_pointsPerPerks[raceId][i] = new int256[](points[i].length);

            for (uint256 j = 0; j < points[i].length; j++) {
                BULLRUN_pointsPerPerks[raceId][i][j] = points[i][j];
            }
        }
    }

    // used to get 3 persons with maximum points
    function BULLRUN_getWinnersPerGame(uint256 raceId) public view returns (
        address user1,
        address user2,
        address user3
    ) {
        int256 highest = 0;
        int256 secondHighest = 0;
        int256 thirdHighest = 0;

        address highestUser = address(0);
        address secondHighestUser = address(0);
        address thirdHighestUser = address(0);

        if (BULLRUN_gameParticipants[raceId].length > 0) {
            // loop through the participants
            for (uint256 i = 0; i < BULLRUN_gameParticipants[raceId].length; i++) {
                address participant = BULLRUN_gameParticipants[raceId][i];
                int256 points = BULLRUN_getAmountOfPointsPerGame(participant, raceId);

                if (points > highest) {
                    thirdHighest      = secondHighest;
                    thirdHighestUser  = secondHighestUser;
                    secondHighest     = highest;
                    secondHighestUser = highestUser;
                    highest           = points;
                    highestUser       = participant;
                } else if (points > secondHighest) {
                    thirdHighest      = secondHighest;
                    thirdHighestUser  = secondHighestUser;
                    secondHighest     = points;
                    secondHighestUser = participant;
                } else if (points > thirdHighest) {
                    thirdHighest      = points;
                    thirdHighestUser  = participant;
                }
            }
        }

        return (highestUser, secondHighestUser, thirdHighestUser);
    }

    function BULLRUN_getPerksMatrix(uint256 raceId) public view returns (int256[3][3] memory perksMatrix) {
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = 0; j < 3; j++) {
                perksMatrix[i][j] = BULLRUN_pointsPerPerks[raceId][i][j];
            }
        }
    }

    // function to retrieve user choices
    function BULLRUN_getUserChoicesPerks(uint256 raceId, address user) public view returns (uint256[] memory) {
        return BULLRUN_usersChoices[raceId][user].selectedPerks;
    }
}
