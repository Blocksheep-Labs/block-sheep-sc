// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { BlockSheep } from "./BlockSheep.sol";

contract GAME_Bullrun {
    BlockSheep PARENT_BLOCKSHEEP;

    // Struct to track user rooms
    struct BULLRUN_Room {
        int256 userPerkIndex;
        int256 opponentPerkIndex;
        bool userPerkWasSet;
        bool opponentPerkWasSet;
    }

    // Struct to hold user choices and points
    struct BULLRUN_UserChoices {
        uint256[] selectedPerks;
        int256 points;
    }

    // user choices and points by raceId and user address
    mapping(uint256 => mapping(address => BULLRUN_UserChoices)) private BULLRUN_usersChoices;

    // Unique identifier for each session
    mapping(uint256 => mapping(address => mapping(address => BULLRUN_Room))) private BULLRUN_gameSessions;

    // points per perks per raceId
    mapping(uint256 => mapping(uint256 => int256[])) public BULLRUN_pointsPerPerks;

    // Track users who have participated in each game
    mapping(uint256 => address[]) public BULLRUN_gameParticipants;

    constructor(address blocksheepAddress) {
        PARENT_BLOCKSHEEP = BlockSheep(blocksheepAddress);
    }

    function BULLRUN_getAmountOfPointsPerGame(address user, uint256 raceId) public view returns (int256) {
        return BULLRUN_usersChoices[raceId][user].points;
    }

    function BULLRUN_makeChoice(
        uint256 raceId,
        uint256 perkIndex,
        address opponentAddress
    ) public {
        PARENT_BLOCKSHEEP.validateGameCompletion(raceId, "rabbit-hole");
        require(perkIndex < 3, "Invalid perk index");

        // Ensure the opponent is not the same as the caller
        require(msg.sender != opponentAddress, "Cannot play against yourself");

        // Retrieve or initialize the session for the current race and opponent
        BULLRUN_Room storage currentRoom = BULLRUN_gameSessions[raceId][msg.sender][opponentAddress];

        // Set the perks based on the caller's role
        if (!currentRoom.userPerkWasSet) {
            currentRoom.userPerkIndex = int256(perkIndex);
            currentRoom.userPerkWasSet = true;
        } else {
            revert("User perk already set for this round");
        }

        BULLRUN_Room storage opponentRoom = BULLRUN_gameSessions[raceId][opponentAddress][msg.sender];
        if (currentRoom.userPerkWasSet && opponentRoom.userPerkWasSet) {
            // Both choices have been made, calculate points and reset state
            int256 userPoints     = BULLRUN_pointsPerPerks[raceId][uint256(currentRoom.userPerkIndex)][uint256(opponentRoom.userPerkIndex)];
            int256 opponentPoints = BULLRUN_pointsPerPerks[raceId][uint256(opponentRoom.userPerkIndex)][uint256(currentRoom.userPerkIndex)];
            
            // Update points for both user and opponent
            BULLRUN_usersChoices[raceId][msg.sender].points      += userPoints;
            BULLRUN_usersChoices[raceId][opponentAddress].points += opponentPoints;

            // Reset the state for the next round
            delete BULLRUN_gameSessions[raceId][msg.sender][opponentAddress];
            delete BULLRUN_gameSessions[raceId][opponentAddress][msg.sender];
        }

        // Record both users' participation if not already recorded
        if (!isParticipant(raceId, msg.sender)) {
            BULLRUN_gameParticipants[raceId].push(msg.sender);
        }
        if (!isParticipant(raceId, opponentAddress)) {
            BULLRUN_gameParticipants[raceId].push(opponentAddress);
        }
    }

    // Utility function to check if a user has already participated in a race
    function isParticipant(uint256 raceId, address user) internal view returns (bool) {
        for (uint256 i = 0; i < BULLRUN_gameParticipants[raceId].length; i++) {
            if (BULLRUN_gameParticipants[raceId][i] == user) {
                return true;
            }
        }
        return false;
    }

    function BULLRUN_setPointsPerPerksForRace(uint256 raceId, int256[3][3] calldata points) public {
        if (PARENT_BLOCKSHEEP.userHasAdminAccess(msg.sender) == false) {
            revert("Sender is not an admin");
        }

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
        PARENT_BLOCKSHEEP.validateRaceId(raceId);
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
                    thirdHighest = secondHighest;
                    thirdHighestUser = secondHighestUser;
                    secondHighest = highest;
                    secondHighestUser = highestUser;
                    highest = points;
                    highestUser = participant;
                } else if (points > secondHighest) {
                    thirdHighest = secondHighest;
                    thirdHighestUser = secondHighestUser;
                    secondHighest = points;
                    secondHighestUser = participant;
                } else if (points > thirdHighest) {
                    thirdHighest = points;
                    thirdHighestUser = participant;
                }
            }
        }

        return (highestUser, secondHighestUser, thirdHighestUser);
    }

    function BULLRUN_getPerksMatrix(uint256 raceId) public view returns (int256[3][3] memory perksMatrix) {
        PARENT_BLOCKSHEEP.validateRaceId(raceId);
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = 0; j < 3; j++) {
                perksMatrix[i][j] = BULLRUN_pointsPerPerks[raceId][i][j];
            }
        }
    }

    // function to retrieve user choices titles
    function BULLRUN_getUserChoicesIndexes(uint256 raceId, address user) public view returns (uint256[] memory) {
        PARENT_BLOCKSHEEP.validateRaceId(raceId);
        return BULLRUN_usersChoices[raceId][user].selectedPerks;
    }
}
