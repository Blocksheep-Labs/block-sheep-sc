// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

contract GAME_RabbitHole {
    address public BLOCKSHEEP_ADDR;
    
    // user chioces by gameId
    //        raceId           roundId           user          fuelSubmitted
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public RABBITHOLE_usersChoices;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public RABBITHOLE_usersRemainingFuel;

    mapping(uint256 => address) public RABBITHOLE_winner;

    mapping(uint256 => mapping(address => uint256)) public RABBITHOLE_points;

    // Track users who have participated in each game
    //      raceId      user-addrs
    mapping(uint256 => mapping(uint256 => address[])) public RABBITHOLE_roundParticipants;

    //        raceId           roundId           user         participated in?
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public RABBITHOLE_roundWasParticipated;
    //        raceId           roundId     user
    mapping(uint256 => mapping(uint256 => address)) public RABBITHOLE_eliminatedAtRound;


    constructor(
        address blocksheep
    ) {
        BLOCKSHEEP_ADDR = blocksheep;
    }


    function submitFuel(
        uint256 raceId,
        uint256 fuelSubmission,
        uint256 fuelLeft,
        uint256 roundIndex
    ) external {
        // if was not participated at the round, mark as participated and store fuel data
        if (RABBITHOLE_roundWasParticipated[raceId][roundIndex][msg.sender] == false) {
            RABBITHOLE_roundParticipants[raceId][roundIndex].push(msg.sender);
            RABBITHOLE_usersChoices[raceId][roundIndex][msg.sender] = fuelSubmission;
            RABBITHOLE_usersRemainingFuel[raceId][roundIndex][msg.sender] = fuelLeft;
        }

        // mark user in round as participated
        RABBITHOLE_roundWasParticipated[raceId][roundIndex][msg.sender] = true;

        // TODO: 
        // get and update the player to eliminate at the round
        // use RABBITHOLE_eliminatedAtRound, RABBITHOLE_usersChoices
    }

    function finishTunnelGame(
        uint256 raceId,
        bool isWon,
        uint256 pointsToAllocate
    ) external {
        /*
        RabbitTunnel storage rabbitTunnel = RABBITHOLE_tunnels[raceId];
        rabbitTunnel.pointsAddresses.push(msg.sender);
        rabbitTunnel.pointsAmount.push(pointsToAllocate);

        rabbitTunnel.finishedBy.push(msg.sender);
        if (isWon) {
            rabbitTunnel.winner = msg.sender;
        }
        */



        // TODO: based on played rounds
        // and eliminated users in previous rounds
        // determine the winner of the game
    }
}