// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IGameInterface } from "./IGameInterface.sol";

contract GameWhaleteeth is IGameInterface {
  int256 public constant BPS = 1000;

  mapping(uint256 => address[]) public WHALETEETH_allPlayers;
  mapping(uint256 => mapping(address => bool)) public WHALETEETH_changedTyresBeforeTheGame;
  mapping(uint256 => mapping(address => int256)) public WHALETEETH_points;
  mapping(uint256 => bool) private WHALETEETH_distributed;
  mapping(uint256 => address[]) public WHALETEETH_gameParticipants;


  function getPoints(address user, uint256 raceId) public view returns (int256) {
    int256 points = WHALETEETH_points[raceId][user];

    if (WHALETEETH_changedTyresBeforeTheGame[raceId][user]) {
      points = points * 25 / 10;
    }

    return points;
  }

  function getInternalScore(address, uint256) public pure returns (int256) {
    return 0;
  }

  function getUserChoices(uint256, address) public pure returns (uint256[] memory) {
    uint256[] memory emptyArray = new uint256[](0);
    return emptyArray;
  }

  function getWinner(uint256 raceId) external view returns (address[] memory, int256[] memory) {
    address[] memory participants = WHALETEETH_gameParticipants[raceId];
    uint256 count = participants.length;


    address[] memory sortedAddresses = new address[](count);
    int256[] memory sortedPoints = new int256[](count);


    for (uint256 i = 0; i < count; i++) {
      sortedAddresses[i] = participants[i];
      sortedPoints[i] = getPoints(participants[i], raceId);
    }


    for (uint256 i = 0; i < count; i++) {
      for (uint256 j = i + 1; j < count; j++) {
        if (sortedPoints[j] > sortedPoints[i]) {
          (sortedPoints[i], sortedPoints[j]) = (sortedPoints[j], sortedPoints[i]);
          (sortedAddresses[i], sortedAddresses[j]) = (sortedAddresses[j], sortedAddresses[i]);
        }
      }
    }

    return (sortedAddresses, sortedPoints);
  }

  function getRules(uint256 raceId) external pure returns (bytes memory) {
    return abi.encode(raceId);
  }

  function makeMove(uint256, bytes calldata) public pure {
    return;
  }

  function distribute(uint256 raceId, bytes memory data) external {
    // if (WHALETEETH_distributed[raceId]) {
    //    return;
    // }

    (address[] memory players, int256[] memory points) = abi.decode(data, (address[], int256[]));

    require(players.length == points.length, "Mismatched data length");

    for (uint256 i = 0; i < players.length; i++) {
      WHALETEETH_points[raceId][players[i]] = points[i] * BPS;
      WHALETEETH_gameParticipants[raceId].push(players[i]); // Добавляем игрока в participants
    }

    WHALETEETH_distributed[raceId] = true;
  }

  function initRace(uint256 raceid, bytes memory data) external {
    // no need additional logic to init race
  }

  function changeTyres(uint256 raceId, address user) public {
    WHALETEETH_changedTyresBeforeTheGame[raceId][user] = true;
  }
}