// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IGameInterface } from "./IGameInterface.sol";

contract GameBullrun is IGameInterface {
    // Struct to track user rooms
    struct BULLRUN_Room {
        uint256 userPerkIndex;
        uint256 opponentPerkIndex;
        bool userPerkWasSet;
        bool opponentPerkWasSet;
        bool distributed;
    }

    // Struct to hold user choices and points
    struct BULLRUN_UserChoices {
        uint256[] selectedPerks;
        int256 points;
    }

    // user choices and points by raceId and user address
    mapping(uint256 => mapping(address => BULLRUN_UserChoices)) private BULLRUN_usersChoices;

    // Unique identifier for each session
    //       raceId             user             opponent     
    mapping(uint256 => mapping(address => mapping(address => BULLRUN_Room))) private BULLRUN_gameSessions;

    // points per perks per raceId
    mapping(uint256 => mapping(uint256 => int256[])) public BULLRUN_pointsPerPerks;

    // Track users who have participated in each game
    mapping(uint256 => address[]) private BULLRUN_gameParticipants;


    mapping(uint256 => mapping(address => mapping(address => bool))) private BULLRUN_opponentsPlayed;



    // function to retrieve user points
    function getPoints(address user, uint256 raceId) public view returns (int256) {
        address[] memory participants = BULLRUN_gameParticipants[raceId];
        uint256 length = participants.length;

        if (length == 0) {
            return 0; // No participants, return 0
        }

        int256 highest = type(int256).min;
        int256 secondHighest = type(int256).min;
        int256 thirdHighest = type(int256).min;

        address highestUser = address(0);
        address secondHighestUser = address(0);
        address thirdHighestUser = address(0);

        // Determine the top 3 players
        for (uint256 i = 0; i < length; i++) {
            address participant = participants[i];
            int256 USERpoints = BULLRUN_usersChoices[raceId][participant].points;

            if (USERpoints > highest) {
                thirdHighest = secondHighest;
                thirdHighestUser = secondHighestUser;
                secondHighest = highest;
                secondHighestUser = highestUser;
                highest = USERpoints;
                highestUser = participant;
            } else if (USERpoints > secondHighest) {
                thirdHighest = secondHighest;
                thirdHighestUser = secondHighestUser;
                secondHighest = USERpoints;
                secondHighestUser = participant;
            } else if (USERpoints > thirdHighest) {
                thirdHighest = USERpoints;
                thirdHighestUser = participant;
            }
        }

        // Assign points based on ranking
        if (user == highestUser) {
            return 3;
        } else if (user == secondHighestUser) {
            return 2;
        } else if (user == thirdHighestUser) {
            return 1;
        } else {
            return 0;
        }
    }

    function getInternalScore(address user, uint256 raceId) public view returns (int256) {
        return BULLRUN_usersChoices[raceId][user].points;
    }

    // function to retrieve user choices indexes
    function getUserChoices(uint256 raceId, address user) public view returns (uint256[] memory) {
        return BULLRUN_usersChoices[raceId][user].selectedPerks;
    }


    function makeMove(
        uint256 raceId,
        bytes memory data
    ) public {
        (uint256 perkIndex, address opponentAddress, address sender) = abi.decode(data, (uint256, address, address));
        //PARENT_BLOCKSHEEP.validateGameCompletion(raceId, "rabbit-hole");
        require(perkIndex < 3, "Invalid perk index");

        // Ensure the opponent is not the same as the caller
        require(sender != opponentAddress, "Cannot play against yourself");


        // player should not play with repeated opp
        require(!BULLRUN_opponentsPlayed[raceId][sender][opponentAddress], "Already played with this opponent");
        BULLRUN_opponentsPlayed[raceId][sender][opponentAddress] = true;


        // Retrieve or initialize the session for the current race and opponent
        BULLRUN_Room storage currentRoom = BULLRUN_gameSessions[raceId][sender][opponentAddress];

        // Set the perks based on the caller's role
        if (!currentRoom.userPerkWasSet) {
            currentRoom.userPerkIndex = uint256(perkIndex);
            currentRoom.userPerkWasSet = true;
        } else {
            revert("User perk already set for this round");
        }

        BULLRUN_Room storage opponentRoom = BULLRUN_gameSessions[raceId][opponentAddress][sender];
        opponentRoom.opponentPerkIndex = uint256(perkIndex);
        opponentRoom.opponentPerkWasSet = true;

        // Record both users' participation if not already recorded
        if (!_isParticipant(raceId, sender)) {
            BULLRUN_gameParticipants[raceId].push(sender);
        }
        if (!_isParticipant(raceId, opponentAddress)) {
            BULLRUN_gameParticipants[raceId].push(opponentAddress);
        }
    }

    function distribute(
        uint256 raceId,
        bytes memory data
    ) public {
        (address opponentAddress, address sender) = abi.decode(data, (address, address));

        // Ensure the opponent is not the same as the caller
        require(sender != opponentAddress, "Cannot play against yourself");

        // Retrieve or initialize the session for the current race and opponent
        BULLRUN_Room storage currentRoom = BULLRUN_gameSessions[raceId][sender][opponentAddress];
        BULLRUN_Room storage opponentRoom = BULLRUN_gameSessions[raceId][opponentAddress][sender];

        if (currentRoom.userPerkWasSet && !opponentRoom.userPerkWasSet) { // 1 user selected sth, 2nd nothing => user1 + 1 point, user2 - 1 point
            if (!currentRoom.distributed) {
                BULLRUN_usersChoices[raceId][sender].points += 1;
                BULLRUN_usersChoices[raceId][sender].selectedPerks.push(currentRoom.userPerkIndex);
            }
            if (!opponentRoom.distributed) {
                BULLRUN_usersChoices[raceId][opponentAddress].points -= 1;
                BULLRUN_usersChoices[raceId][opponentAddress].selectedPerks.push(1);
            }
        } else if (!currentRoom.userPerkWasSet && opponentRoom.userPerkWasSet) { // 1 user selected sth, 2nd nothing => user1 + 1 point, user2 - 1 point
            if (!currentRoom.distributed) {
                BULLRUN_usersChoices[raceId][sender].points -= 1;
                BULLRUN_usersChoices[raceId][sender].selectedPerks.push(1);
            }
            if (!opponentRoom.distributed) {
                BULLRUN_usersChoices[raceId][opponentAddress].points += 1;
                BULLRUN_usersChoices[raceId][opponentAddress].selectedPerks.push(opponentRoom.userPerkIndex);
            }
        } else if (!currentRoom.userPerkWasSet && !opponentRoom.userPerkWasSet) { // both of users selected nothing => -1 for all (2 users)
            if (!currentRoom.distributed) {
                BULLRUN_usersChoices[raceId][sender].points -= 1;
                BULLRUN_usersChoices[raceId][sender].selectedPerks.push(1);
            }
            if (!opponentRoom.distributed) {
                BULLRUN_usersChoices[raceId][opponentAddress].points -= 1;
                BULLRUN_usersChoices[raceId][opponentAddress].selectedPerks.push(1);
            }
        }

        if (currentRoom.userPerkWasSet && opponentRoom.userPerkWasSet) {  
            // Update points for both user and opponent
            if (!currentRoom.distributed) {
                int256 userPoints = BULLRUN_pointsPerPerks[raceId][uint256(currentRoom.userPerkIndex)][uint256(opponentRoom.userPerkIndex)];
                BULLRUN_usersChoices[raceId][sender].points += userPoints;
                BULLRUN_usersChoices[raceId][sender].selectedPerks.push(currentRoom.userPerkIndex);
            }

            if (!opponentRoom.distributed) {
                int256 opponentPoints = BULLRUN_pointsPerPerks[raceId][uint256(opponentRoom.userPerkIndex)][uint256(currentRoom.userPerkIndex)];
                BULLRUN_usersChoices[raceId][opponentAddress].points += opponentPoints;
                BULLRUN_usersChoices[raceId][opponentAddress].selectedPerks.push(opponentRoom.userPerkIndex);
            }
        }

        currentRoom.distributed = true;
        opponentRoom.distributed = true;
    }

    function initRace(uint256 raceId, bytes calldata initState) public {
        int256[3][3] memory points = abi.decode(initState, (int256[3][3]));
        
        require(points.length > 0, "Points matrix cannot be empty");

        for (uint256 i = 0; i < points.length; i++) {
            BULLRUN_pointsPerPerks[raceId][i] = new int256[](points[i].length);
            for (uint256 j = 0; j < points[i].length; j++) {
                BULLRUN_pointsPerPerks[raceId][i][j] = points[i][j];
            }
        }
    }

    // used to get 3 persons with maximum points
    function getWinner(uint256 raceId) public view returns (address[] memory, int256[] memory) {
        int256 highest = type(int256).min;
        int256 secondHighest = type(int256).min;
        int256 thirdHighest = type(int256).min;

        address highestUser = address(0);
        address secondHighestUser = address(0);
        address thirdHighestUser = address(0);

        address[] memory users = new address[](3);
        int256[] memory points = new int256[](3);

        if (BULLRUN_gameParticipants[raceId].length > 0) {
            // loop through the participants
            for (uint256 i = 0; i < BULLRUN_gameParticipants[raceId].length; i++) {
                address participant = BULLRUN_gameParticipants[raceId][i];
                int256 USERpoints = getPoints(participant, raceId);

                if (USERpoints > highest) {
                    thirdHighest = secondHighest;
                    thirdHighestUser = secondHighestUser;
                    secondHighest = highest;
                    secondHighestUser = highestUser;
                    highest = USERpoints;
                    highestUser = participant;
                } else if (USERpoints > secondHighest) {
                    thirdHighest = secondHighest;
                    thirdHighestUser = secondHighestUser;
                    secondHighest = USERpoints;
                    secondHighestUser = participant;
                } else if (USERpoints > thirdHighest) {
                    thirdHighest = USERpoints;
                    thirdHighestUser = participant;
                }
            }
        }

        users[0] = highestUser;
        users[1] = secondHighestUser;
        users[2] = thirdHighestUser;

        points[0] = getPoints(highestUser, raceId);
        points[1] = getPoints(secondHighestUser, raceId);
        points[2] = getPoints(thirdHighestUser, raceId);

        return (users, points);
    }

    function getRules(uint256 raceId) public view returns (bytes memory) {
        int256[3][3] memory perksMatrix;
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = 0; j < 3; j++) {
                perksMatrix[i][j] = BULLRUN_pointsPerPerks[raceId][i][j];
            }
        }

        return abi.encode(perksMatrix);
    }

    
    // Utility function to check if a user has already participated in a race
    function _isParticipant(uint256 raceId, address user) internal view returns (bool) {
        for (uint256 i = 0; i < BULLRUN_gameParticipants[raceId].length; i++) {
            if (BULLRUN_gameParticipants[raceId][i] == user) {
                return true;
            }
        }
        return false;
    }
}
