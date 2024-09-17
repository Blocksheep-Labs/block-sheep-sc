// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

contract GAME_Bullrun {
    // main contract address
    address public BLOCKSHEEP_ADDR;

    // user chioces by gameId as an array of string
    //      raceId            user-addr    choices
    mapping(uint256 => mapping(address => string[])) public usersChoices;

    // points per perks per gameId
    //       raceId           perk-name   points
    mapping(uint256 => mapping(string => uint256)) public pointsPerPerks;


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
        for (uint256 i = 0; i < usersChoices[raceId][user].length; i++) {
            // incr or decr the points based on answer
            string storage choice = usersChoices[raceId][user][i];
            points += pointsPerPerks[raceId][choice];
        }
    }

    function makeChoice(uint256 raceId, string calldata choice) public {
        // add user to participants on the 1st choice
        if (usersChoices[raceId][msg.sender].length == 0) {
            gameParticipants[raceId].push(msg.sender);
        }
        usersChoices[raceId][msg.sender].push(choice);
    }

    function setPointsPerPerksForRace(
        uint256 raceId, 
        string[] calldata perks, 
        uint256[] calldata points
    ) public {
        require(perks.length == points.length, "Perks and Points lengths are not equal");
        for (uint256 i = 0; i < perks.length; i++) {
            pointsPerPerks[raceId][perks[i]] = points[i];
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

} 