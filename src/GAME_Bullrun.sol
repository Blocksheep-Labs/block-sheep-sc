// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

contract GAME_Bullrun {
    // main contract address
    address public BLOCKSHEEP_ADDR;

    // user chioces by gameId as an array of string
    //      raceId            user-addr    choices
    mapping(uint256 => mapping(address => string[]))  public usersChoicesTitles;
    mapping(uint256 => mapping(address => uint256[])) public usersChoicesPoints;

    // points per perks per gameId
    //       raceId           perk-name   points
    mapping(uint256 => mapping(uint256 => int256[])) public pointsPerPerks;


    // Track users who have participated in each game
    //      raceId      user-addrs
    mapping(uint256 => address[]) public gameParticipants;


    constructor(
        address blocksheep
    ) {
        BLOCKSHEEP_ADDR = blocksheep;
    }

    function getAmountOfPointsPerGame(address user, uint256 raceId) public view returns(uint256 points) {
        points = 0;
        // iterate over the answers
        for (uint256 i = 0; i < usersChoicesPoints[raceId][user].length; i++) {
            // incr or decr the points based on answer
            points += usersChoicesPoints[raceId][user][i];
        }
    }

    function makeChoice(uint256 raceId, string calldata choice, uint256 points) public {
        // add user to participants on the 1st choice
        if (usersChoicesTitles[raceId][msg.sender].length == 0) {
            gameParticipants[raceId].push(msg.sender);
        }
        usersChoicesTitles[raceId][msg.sender].push(choice);
        usersChoicesPoints[raceId][msg.sender].push(points);
    }

    function setPointsPerPerksForRace(
        uint256 raceId, 
        int256[3][3] calldata points
    ) public {
        require(points.length > 0, "Points matrix cannot be empty");
        for (uint256 i = 0; i < points.length; i++) {
            pointsPerPerks[raceId][i] = new int256[](points[i].length);

            for (uint256 j = 0; j < points[i].length; j++) {
                pointsPerPerks[raceId][i][j] = points[i][j];
            }
        }
    }

    // used to get 3 persons will maximum points
    function getWinnersPerGame(uint256 raceId) public view returns(
        address user1,
        address user2,
        address user3
    ) {
        uint256 highest = 0;
        uint256 secondHighest = 0;
        uint256 thirdHighest = 0;

        address highestUser = address(0);
        address secondHighestUser = address(0);
        address thirdHighestUser = address(0);

        if (gameParticipants[raceId].length > 0) {
            // loop through the participants
            for (uint256 i = 0; i < gameParticipants[raceId].length; i++) {
                address participant = gameParticipants[raceId][i];
                uint256 points = getAmountOfPointsPerGame(participant, raceId);

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


    function getPerksMatrix(uint256 raceId) public view returns (int256[3][3] memory perksMatrix) {
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = 0; j < 3; j++) {
                perksMatrix[i][j] = pointsPerPerks[raceId][i][j];
            }
        }
    }


} 