pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import {BlockSheep} from "../src/BlockSheep.sol";

contract AddGameAndQuestions is Script {
    BlockSheep internal blockSheep =
        BlockSheep(0xC31d4F4BfEe38421a1F7704D0632d6F2b15B44ef);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        blockSheep.addGameName("Quiz");
        // Get 3 random questions from the total list
        blockSheep.addQuestions(getRandomQuestions());
        vm.stopBroadcast();
    }

    function getRandomQuestions() internal view returns (BlockSheep.QuestionInfo[] memory questions)
    {
        // Array with all 42 questions
        BlockSheep.QuestionInfo[] memory allQuestions = getQuestionsList();
        
        // Array for storing the selected 3 random questions
        questions = new BlockSheep.QuestionInfo[](3);
        
        // Randomly pick 3 different indices from 0 to 41
        uint256[3] memory randomIndices = [uint256(0), uint256(1), uint256(2)];
        randomIndices = getRandomIndices(44);

        // Assign randomly picked questions
        for (uint256 i = 0; i < 3; i++) {
            questions[i] = allQuestions[randomIndices[i]];
        }
    }

    function getQuestionsList() internal pure returns (BlockSheep.QuestionInfo[] memory allQuestions)
    {
        // Initialize array with 42 questions
        allQuestions = new BlockSheep.QuestionInfo[](44);
        
        // Here you add all 42 questions in the same way as the initial example
        allQuestions[0].content = "Is it better to have nice or smart kids?";
        allQuestions[0].answers = new string[](2);
        allQuestions[0].answers[0] = "Smart"; allQuestions[0].answers[1] = "Nice";

        allQuestions[1].content = "Would you rather explore the depths of the ocean or outer space?";
        allQuestions[1].answers = new string[](2);
        allQuestions[1].answers[0] = "Ocean"; allQuestions[1].answers[1] = "Space";

        allQuestions[2].content = "Would you rather read minds or being able to teleport?";
        allQuestions[2].answers = new string[](2);
        allQuestions[2].answers[0] = "Read"; allQuestions[2].answers[1] = "Teleport";

        allQuestions[3].content = "Is honesty always the best policy?";
        allQuestions[3].answers = new string[](2);
        allQuestions[3].answers[0] = "Yes"; allQuestions[3].answers[1] = "No";

        allQuestions[4].content = "Should you follow your passion or choose a stable career?";
        allQuestions[4].answers = new string[](2);
        allQuestions[4].answers[0] = "Passion"; allQuestions[4].answers[1] = "Stability";

        allQuestions[5].content = "Is privacy more important than security?";
        allQuestions[5].answers = new string[](2);
        allQuestions[5].answers[0] = "Privacy"; allQuestions[5].answers[1] = "Security";

        allQuestions[6].content = "Should success be measured by wealth or happiness?";
        allQuestions[6].answers = new string[](2);
        allQuestions[6].answers[0] = "Wealth"; allQuestions[6].answers[1] = "Happiness";

        allQuestions[7].content = "Is it better to focus on the individual or the group?";
        allQuestions[7].answers = new string[](2);
        allQuestions[7].answers[0] = "Individual"; allQuestions[7].answers[1] = "Group";

        allQuestions[8].content = "Would you rather be feared or loved as a leader?";
        allQuestions[8].answers = new string[](2);
        allQuestions[8].answers[0] = "Feared"; allQuestions[8].answers[1] = "Loved";

        allQuestions[9].content = "Is it more ethical to tell a painful truth or a comforting lie?";
        allQuestions[9].answers = new string[](2);
        allQuestions[9].answers[0] = "Truth"; allQuestions[9].answers[1] = "Lie";

        allQuestions[10].content = "Should you live for today or plan for the future?";
        allQuestions[10].answers = new string[](2);
        allQuestions[10].answers[0] = "Today"; allQuestions[10].answers[1] = "Future";

        allQuestions[11].content = "Is it more important to be free or safe?";
        allQuestions[11].answers = new string[](2);
        allQuestions[11].answers[0] = "Free"; allQuestions[11].answers[1] = "Safe";

        allQuestions[12].content = "Is competition or cooperation the key to success?";
        allQuestions[12].answers = new string[](2);
        allQuestions[12].answers[0] = "Competition"; allQuestions[12].answers[1] = "Cooperation";

        allQuestions[13].content = "Is it more important to be respected or liked?";
        allQuestions[13].answers = new string[](2);
        allQuestions[13].answers[0] = "Respected"; allQuestions[13].answers[1] = "Liked";

        allQuestions[14].content = "Should we prioritize personal freedom or the greater good?";
        allQuestions[14].answers = new string[](2);
        allQuestions[14].answers[0] = "Freedom"; allQuestions[14].answers[1] = "Greater good";

        allQuestions[15].content = "Is it better to be rich or happy?";
        allQuestions[15].answers = new string[](2);
        allQuestions[15].answers[0] = "Rich"; allQuestions[15].answers[1] = "Happy";

        allQuestions[16].content = "Truth even if it hurts, or live in ignorance?";
        allQuestions[16].answers = new string[](2);
        allQuestions[16].answers[0] = "Truth"; allQuestions[16].answers[1] = "Ignorance";

        allQuestions[17].content = "Better to help 1 person greatly or many people a little?";
        allQuestions[17].answers = new string[](2);
        allQuestions[17].answers[0] = "One"; allQuestions[17].answers[1] = "Many";

        allQuestions[18].content = "Invest in space exploration or solving Earth's problems?";
        allQuestions[18].answers = new string[](2);
        allQuestions[18].answers[0] = "Space"; allQuestions[18].answers[1] = "Earth";

        allQuestions[19].content = "Life of comfort or of adventure?";
        allQuestions[19].answers = new string[](2);
        allQuestions[19].answers[0] = "Comfort"; allQuestions[19].answers[1] = "Adventure";

        allQuestions[20].content = "Is it better to be a leader or a follower in life?";
        allQuestions[20].answers = new string[](2);
        allQuestions[20].answers[0] = "Leader"; allQuestions[20].answers[1] = "Follower";

        allQuestions[21].content = "Sacrifice privacy for safety or keep privacy at all costs?";
        allQuestions[21].answers = new string[](2);
        allQuestions[21].answers[0] = "Privacy"; allQuestions[21].answers[1] = "Safety";

        allQuestions[22].content = "Is it more important to live for yourself or for others?";
        allQuestions[22].answers = new string[](2);
        allQuestions[22].answers[0] = "Yourself"; allQuestions[22].answers[1] = "Others";

        allQuestions[23].content = "Is free will real or an illusion?";
        allQuestions[23].answers = new string[](2);
        allQuestions[23].answers[0] = "Real"; allQuestions[23].answers[1] = "Illusion";

        allQuestions[24].content = "Does life have inherent meaning, or do we create it ourselves?";
        allQuestions[24].answers = new string[](2);
        allQuestions[24].answers[0] = "Inherent"; allQuestions[24].answers[1] = "Created";

        allQuestions[25].content = "Should we challenge social norms, or follow them for stability?";
        allQuestions[25].answers = new string[](2);
        allQuestions[25].answers[0] = "Challenge"; allQuestions[25].answers[1] = "Follow";

        allQuestions[26].content = "Is it more important to respect tradition or embrace change?";
        allQuestions[26].answers = new string[](2);
        allQuestions[26].answers[0] = "Tradition"; allQuestions[26].answers[1] = "Change";

        allQuestions[27].content = "Should AI be given human rights if it becomes conscious?";
        allQuestions[27].answers = new string[](2);
        allQuestions[27].answers[0] = "Yes"; allQuestions[27].answers[1] = "No";

        allQuestions[28].content = "Will technology unite humanity or divide us further?";
        allQuestions[28].answers = new string[](2);
        allQuestions[28].answers[0] = "Unite"; allQuestions[28].answers[1] = "Divide";

        allQuestions[29].content = "Is it justifiable to break the law if it helps others?";
        allQuestions[29].answers = new string[](2);
        allQuestions[29].answers[0] = "Yes"; allQuestions[29].answers[1] = "No";

        allQuestions[30].content = "Should you prioritize the well-being of family or society?";
        allQuestions[30].answers = new string[](2);
        allQuestions[30].answers[0] = "Family"; allQuestions[30].answers[1] = "Society";

        allQuestions[31].content = "Do emotions or logic guide better decisions?";
        allQuestions[31].answers = new string[](2);
        allQuestions[31].answers[0] = "Emotions"; allQuestions[31].answers[1] = "Logic";

        allQuestions[32].content = "Is it easier to forgive yourself or others?";
        allQuestions[32].answers = new string[](2);
        allQuestions[32].answers[0] = "Yourself"; allQuestions[32].answers[1] = "Others";

        allQuestions[33].content = "Is love more about passion or companionship?";
        allQuestions[33].answers = new string[](2);
        allQuestions[33].answers[0] = "Passion"; allQuestions[33].answers[1] = "Companionship";

        allQuestions[34].content = "Is it better to flee or fight when in danger?";
        allQuestions[34].answers = new string[](2);
        allQuestions[34].answers[0] = "Flee"; allQuestions[34].answers[1] = "Fight";

        allQuestions[35].content = "Is creativity more a result of talent or hard work?";
        allQuestions[35].answers = new string[](2);
        allQuestions[35].answers[0] = "Talent"; allQuestions[35].answers[1] = "Hard work";

        allQuestions[36].content = "Catchy song stuck in your head or bad haircut?";
        allQuestions[36].answers = new string[](2);
        allQuestions[36].answers[0] = "Song"; allQuestions[36].answers[1] = "Haircut";

        allQuestions[37].content = "Only eat pizza or chocolate forever?";
        allQuestions[37].answers = new string[](2);
        allQuestions[37].answers[0] = "Pizza"; allQuestions[37].answers[1] = "Chocolate";

        allQuestions[38].content = "Talk to animals or speak every language?";
        allQuestions[38].answers = new string[](2);
        allQuestions[38].answers[0] = "Animals"; allQuestions[38].answers[1] = "Languages";

        allQuestions[39].content = "Fight a horse-sized duck or 100 duck-sized horses?";
        allQuestions[39].answers = new string[](2);
        allQuestions[39].answers[0] = "Big duck"; allQuestions[39].answers[1] = "Tiny horses";

        allQuestions[40].content = "Always 10 minutes late or 20 minutes early?";
        allQuestions[40].answers = new string[](2);
        allQuestions[40].answers[0] = "Late"; allQuestions[40].answers[1] = "Early";

        allQuestions[41].content = "Invisibility or flying?";
        allQuestions[41].answers = new string[](2);
        allQuestions[41].answers[0] = "Invisibility"; allQuestions[41].answers[1] = "Flying";

        allQuestions[42].content = "No traffic or no waiting in line?";
        allQuestions[42].answers = new string[](2);
        allQuestions[42].answers[0] = "No traffic"; allQuestions[42].answers[1] = "No lines";

        allQuestions[43].content = "Pause life or rewind it?";
        allQuestions[43].answers = new string[](2);
        allQuestions[43].answers[0] = "Pause"; allQuestions[43].answers[1] = "Rewind";
    }

    function getRandomIndices(uint256 total) internal view returns (uint256[3] memory randomIndices) {
        require(total >= 3, "Total must be at least 3 to get unique indices");

        // Create an array of booleans to track used indices
        bool[] memory used = new bool[](total);

        // Generate 3 unique indices
        for (uint256 i = 0; i < 3; i++) {
            uint256 randomIndex;
            do {
                // Generate a pseudo-random number based on block data
                randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, i))) % total;
            } while (used[randomIndex]); // Check if this index is already used

            // Mark this index as used
            used[randomIndex] = true;
            randomIndices[i] = randomIndex;
        }
    }
}
