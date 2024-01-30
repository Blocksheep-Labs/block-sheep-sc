// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract BlockSheep is Ownable {
    uint8 private constant NUM_OF_PLAYERS_PER_RACE = 9;
    uint64 private constant MIN_SECONDS_BEFORE_START_RACE = 1 hours;
    // questionId => question
    mapping(uint256 => Question) questions;

    uint256 private nextQuestionId;

    // gameNameId => game name
    mapping(uint256 => string) gameNames;

    uint256 private nextGameNameId;

    mapping(uint256 => Race) races;

    uint256 private nextRaceId;

    struct Question {
        string content;
        string[] answers;
    }

    struct Game {
        uint256 gameId;
        uint256[] questionIds;
        mapping(address => Answer) answers;
        // questionId => answerId => count;
        mapping(uint256 => mapping(uint8 => address[])) answersCount;
    }

    struct GameParams {
        uint256 gameId;
        uint256[] questionIds;
    }

    enum RaceStatus {
        CREATED,
        STARTED,
        CANCELLED,
        DISRIBUTTED
    }

    struct Race {
        string name;
        uint64 startAt;
        uint64 endAt;
        Game[] games;
        uint8 playersCount;
        uint8 answersCount;
        bool distributed;
        mapping(address => bool) playerRegistered;
    }

    struct Answer {
        uint8 answerId;
    }

    error InvalidTimestamp();
    error EmptyQuestions();
    error InvalidRaceId();
    error InvalidGameIndex();
    error LengthMismatch();

    constructor(address owner) Ownable(owner) {}

    function submitAnswers(
        uint256 raceId,
        uint8 gameIndex,
        uint256[] memory questionIds,
        uint8[] memory answerIds
    ) external {
        validateRaceId(raceId);
        validateGameIndex(raceId, gameIndex);
        if (questionIds.length != answerIds.length) revert LengthMismatch();

        for (uint i = 0; i < answerIds.length; i++) {}
    }

    function validateRaceId(uint256 raceId) internal view {
        if (raceId >= nextQuestionId) revert InvalidRaceId();
    }

    function validateGameIndex(uint256 raceId, uint8 gameIndex) internal view {
        if (gameIndex >= races[raceId].games.length) revert InvalidGameIndex();
    }

    /// Admin functions
    function addQuestion(
        string memory question,
        string[] memory answers
    ) external onlyOwner {
        Question storage _question = questions[nextQuestionId];
        _question.content = question;
        _question.answers = answers;
        nextQuestionId++;
    }

    function addGameName(string memory gameName) external onlyOwner {
        gameNames[nextGameNameId] = gameName;
        nextGameNameId++;
    }

    function addRace(
        string memory name,
        uint64 startAt,
        uint64 endAt,
        GameParams[] memory games
    ) external onlyOwner {
        if (
            startAt < block.timestamp + MIN_SECONDS_BEFORE_START_RACE ||
            endAt < startAt
        ) revert InvalidTimestamp();
        if (games.length == 0) revert EmptyQuestions();
        Race storage _race = races[nextRaceId];
        _race.name = name;
        _race.startAt = startAt;
        _race.endAt = endAt;
        for (uint i = 0; i < games.length; i++) {
            _race.games[i].gameId = games[i].gameId;
            _race.games[i].questionIds = games[i].questionIds;
        }

        nextRaceId++;
    }
}
