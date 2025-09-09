// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {FHE, euint256, eaddress} from "@fhenixprotocol/contracts/FHE.sol";


interface IGameInterface {
    function getPoints(address user, uint256 raceId) external view returns (int256);

    function getInternalScore(address user, uint256 raceId) external view returns (int256);

    function getUserChoices(uint256 raceId, address user) external view returns (euint256[] memory);

    function getWinner(uint256 raceId) external view returns (address[] memory, int256[] memory);

    function getRules(uint256 raceId) external view returns (bytes memory);

    function makeMove(uint256 raceId, bytes memory data) external;

    function distribute(uint256 raceId, bytes memory data) external;

    function initRace(uint256 raceid, bytes memory data) external;

    function changeTyres(uint256 raceId, address user) external;
}
