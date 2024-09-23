pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import {BlockSheep} from "../src/BlockSheep.sol";

contract AddGameAndQuestions is Script {
    BlockSheep internal blockSheep =
        BlockSheep(0x4B3b9F5afC9CC1083ce44a1c97E3a75490F6cFF0);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // blockSheep.addGameName("Quiz");
        // Get 3 random questions from the total list
        blockSheep.addQuestions(getQuestionsList());
        vm.stopBroadcast();
    }

    function getQuestionsList() internal pure returns (BlockSheep.QuestionInfo[] memory allQuestions)
    {
        // Initialize array with 44 questions
        allQuestions = new BlockSheep.QuestionInfo[](44);
        
        // Here you add all 44 questions in the same way as the initial example
        allQuestions[0].content = "Is it better to have nice or smart kids?";
        allQuestions[0].answers = new string[](2);
        allQuestions[0].answers[0] = "Smart"; allQuestions[0].answers[1] = "Nice";
        allQuestions[0].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeifalh7xa4vexupzelazm26pvx4id746justwbbefphfgjablxm4gq";

        allQuestions[1].content = "Would you rather explore the depths of the ocean or outer space?";
        allQuestions[1].answers = new string[](2);
        allQuestions[1].answers[0] = "Ocean"; allQuestions[1].answers[1] = "Space";
        allQuestions[1].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeibzj5kt6iptaqn3nbf3ph4mnlvnwks7g5eyqllx3xlwpk7m7je4zy";

        allQuestions[2].content = "Would you rather read minds or being able to teleport?";
        allQuestions[2].answers = new string[](2);
        allQuestions[2].answers[0] = "Read"; allQuestions[2].answers[1] = "Teleport";
        allQuestions[2].imgUrl = "https://gateway.pinata.cloud/ipfs/bafkreie3gcaeirx6mpmmptno4tryt4mmv7aotuudsbv562h54bon7vxfyq";

        allQuestions[3].content = "Is honesty always the best policy?";
        allQuestions[3].answers = new string[](2);
        allQuestions[3].answers[0] = "Yes"; allQuestions[3].answers[1] = "No";
        allQuestions[3].imgUrl = "https://gateway.pinata.cloud/ipfs/bafkreifuwys5gb3v4eyf47z32fzmhspidc6g2w7eir6wfwcwcaytqurqji";

        allQuestions[4].content = "Should you follow your passion or choose a stable career?";
        allQuestions[4].answers = new string[](2);
        allQuestions[4].answers[0] = "Passion"; allQuestions[4].answers[1] = "Stability";
        allQuestions[4].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeifybvxtqfatmuabxy27f257vt66x7r73ptsmt7i4xqdsbt75hfati";

        allQuestions[5].content = "Is privacy more important than security?";
        allQuestions[5].answers = new string[](2);
        allQuestions[5].answers[0] = "Privacy"; allQuestions[5].answers[1] = "Security";
        allQuestions[5].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeig3wwrulk4jzcuqapo5hfyeimhqyooystxur4ejckfov2cdepnk5u";

        allQuestions[6].content = "Should success be measured by wealth or happiness?";
        allQuestions[6].answers = new string[](2);
        allQuestions[6].answers[0] = "Wealth"; allQuestions[6].answers[1] = "Happiness";
        allQuestions[6].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeiejmrads4kpmkpybcujyofeifxxzc6vqfysjdeswsq7uqg4ulvyvm";

        allQuestions[7].content = "Is it better to focus on the individual or the group?";
        allQuestions[7].answers = new string[](2);
        allQuestions[7].answers[0] = "Individual"; allQuestions[7].answers[1] = "Group";
        allQuestions[7].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeidl4iyds7buewv7i4ta3fjrcuiykpaamdgseu7beyw5lxdccot2d4";

        allQuestions[8].content = "Would you rather be feared or loved as a leader?";
        allQuestions[8].answers = new string[](2);
        allQuestions[8].answers[0] = "Feared"; allQuestions[8].answers[1] = "Loved";
        allQuestions[8].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeibbwkoc2bgs5uekhrgmvs2sqhtfb6xwc5yycckkeffhjtu3orbtl4";

        allQuestions[9].content = "Is it more ethical to tell a painful truth or a comforting lie?";
        allQuestions[9].answers = new string[](2);
        allQuestions[9].answers[0] = "Truth"; allQuestions[9].answers[1] = "Lie";
        allQuestions[9].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeicf7yfx34kh5qbddah32thh733poxv4wvyds7mc4pqr2m7hbo5oiy";

        allQuestions[10].content = "Should you live for today or plan for the future?";
        allQuestions[10].answers = new string[](2);
        allQuestions[10].answers[0] = "Today"; allQuestions[10].answers[1] = "Future";
        allQuestions[10].imgUrl = "https://gateway.pinata.cloud/ipfs/bafkreibdbg5ypitqjordnzd7oijy2nzkjjjoowg7zfniilfsdg3spvxwy4";

        allQuestions[11].content = "Is it more important to be free or safe?";
        allQuestions[11].answers = new string[](2);
        allQuestions[11].answers[0] = "Free"; allQuestions[11].answers[1] = "Safe";
        allQuestions[11].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeiblsutw4jb5zkkrsa6jaoaow5txk2t3dmtf5jsa3oimkfrbbti6hu";

        allQuestions[12].content = "Is competition or cooperation the key to success?";
        allQuestions[12].answers = new string[](2);
        allQuestions[12].answers[0] = "Competition"; allQuestions[12].answers[1] = "Cooperation";
        allQuestions[12].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeieyy5kjhakrhllww7wtnsbqjpwacfnyqsny7uy6vlzbvnxdbo7xzm";

        allQuestions[13].content = "Is it more important to be respected or liked?";
        allQuestions[13].answers = new string[](2);
        allQuestions[13].answers[0] = "Respected"; allQuestions[13].answers[1] = "Liked";
        allQuestions[13].imgUrl = "https://gateway.pinata.cloud/ipfs/bafkreidtyrmbndfsoz4h5vtwle3jd5xljdoqshyadf4ucyfqcb5f55rd3e";

        allQuestions[14].content = "Should we prioritize personal freedom or the greater good?";
        allQuestions[14].answers = new string[](2);
        allQuestions[14].answers[0] = "Freedom"; allQuestions[14].answers[1] = "Greater good";
        allQuestions[14].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeial2ijycrs6qpqu4j3bt2etwcylxf7zzbi3kis5ags2wo7mo75bom";

        allQuestions[15].content = "Is it better to be rich or happy?";
        allQuestions[15].answers = new string[](2);
        allQuestions[15].answers[0] = "Rich"; allQuestions[15].answers[1] = "Happy";
        allQuestions[15].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeifim5y3p2nsg7cml6ruku4mk4b75x5i5rdp4xzy7nawkubevjqijm";

        allQuestions[16].content = "Truth even if it hurts, or live in ignorance?";
        allQuestions[16].answers = new string[](2);
        allQuestions[16].answers[0] = "Truth"; allQuestions[16].answers[1] = "Ignorance";
        allQuestions[16].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeiezfgzs5auoblpy5pje6555u6ji4i35skzhwtiibu6vsotez5if5e";

        allQuestions[17].content = "Better to help 1 person greatly or many people a little?";
        allQuestions[17].answers = new string[](2);
        allQuestions[17].answers[0] = "One"; allQuestions[17].answers[1] = "Many";
        allQuestions[17].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeibet3vf3kdtgt6x7ne7a43oiwhsz2izx37k3iitlpkyiikv3b3bse";

        allQuestions[18].content = "Invest in space exploration or solving Earth's problems?";
        allQuestions[18].answers = new string[](2);
        allQuestions[18].answers[0] = "Space"; allQuestions[18].answers[1] = "Earth";
        allQuestions[18].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeicf3a5onwjmqnlrejtq5zppyovem6o23ydqupcbmahmsrlvzn2nje";

        allQuestions[19].content = "Life of comfort or of adventure?";
        allQuestions[19].answers = new string[](2);
        allQuestions[19].answers[0] = "Comfort"; allQuestions[19].answers[1] = "Adventure";
        allQuestions[19].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeifs62cy7pcr553z4iizf6dtnw7bvnhfhe4tl6fxjc6qeqnivghokm";

        allQuestions[20].content = "Is it better to be a leader or a follower in life?";
        allQuestions[20].answers = new string[](2);
        allQuestions[20].answers[0] = "Leader"; allQuestions[20].answers[1] = "Follower";
        allQuestions[20].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeid6nhriy3pefqh6ftqlwsbawcwgyrcomctu5b3l6d2j25mcdldzza";

        allQuestions[21].content = "Sacrifice privacy for safety or keep privacy at all costs?";
        allQuestions[21].answers = new string[](2);
        allQuestions[21].answers[0] = "Privacy"; allQuestions[21].answers[1] = "Safety";
        allQuestions[21].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeicfkqbsqynk7zjjn7l2gwejgyulkishb2mptptpjz4rp7tphcdfhe";

        allQuestions[22].content = "Is it more important to live for yourself or for others?";
        allQuestions[22].answers = new string[](2);
        allQuestions[22].answers[0] = "Yourself"; allQuestions[22].answers[1] = "Others";
        allQuestions[22].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeicoibxdbkzfditvwfj2fyckctppttlxcs4xm3ian3bt3vub6x3lqu";

        allQuestions[23].content = "Is free will real or an illusion?";
        allQuestions[23].answers = new string[](2);
        allQuestions[23].answers[0] = "Real"; allQuestions[23].answers[1] = "Illusion";
        allQuestions[23].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeiboahzplgxiytifg7td7snrcvg5phfhz6rmzjm25gkarfdlvt4v5m";

        allQuestions[24].content = "Does life have inherent meaning, or do we create it ourselves?";
        allQuestions[24].answers = new string[](2);
        allQuestions[24].answers[0] = "Inherent"; allQuestions[24].answers[1] = "Created";
        allQuestions[24].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeiea4xwg66vtvbs3cakycyq7gdr4dlqpshkrch7uyrrofshptgghh4";

        allQuestions[25].content = "Should we challenge social norms, or follow them for stability?";
        allQuestions[25].answers = new string[](2);
        allQuestions[25].answers[0] = "Challenge"; allQuestions[25].answers[1] = "Follow";
        allQuestions[25].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeid3du2e7piifxue5sarg32jgddbt3ove6vmlb65wurothcn4bqj6i";

        allQuestions[26].content = "Is it more important to respect tradition or embrace change?";
        allQuestions[26].answers = new string[](2);
        allQuestions[26].answers[0] = "Tradition"; allQuestions[26].answers[1] = "Change";
        allQuestions[26].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeihddbgpbjciqw4gbxx57bizms4cy4pqbevhvy7acuvuqxglimlgim";

        allQuestions[27].content = "Should AI be given human rights if it becomes conscious?";
        allQuestions[27].answers = new string[](2);
        allQuestions[27].answers[0] = "Yes"; allQuestions[27].answers[1] = "No";
        allQuestions[27].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeiethm3wa7gap7dnpcdkrkz3tqdimbpod72d7arub4tpeznqzrsrsa";

        allQuestions[28].content = "Will technology unite humanity or divide us further?";
        allQuestions[28].answers = new string[](2);
        allQuestions[28].answers[0] = "Unite"; allQuestions[28].answers[1] = "Divide";
        allQuestions[28].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeiautvvooyfvrhh2ibjij4ah6hu2dis6hql6lg36xhwdlb6x32fs2u";

        allQuestions[29].content = "Is it justifiable to break the law if it helps others?";
        allQuestions[29].answers = new string[](2);
        allQuestions[29].answers[0] = "Yes"; allQuestions[29].answers[1] = "No";
        allQuestions[29].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeigv7k5np7sejkkssjp6fugcqz5pi6jqqlgxnmvq26wz4yh3h4egda";

        allQuestions[30].content = "Should you prioritize the well-being of family or society?";
        allQuestions[30].answers = new string[](2);
        allQuestions[30].answers[0] = "Family"; allQuestions[30].answers[1] = "Society";
        allQuestions[30].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeiel373bft2yutqeoz2he6ujvt6wofpiprrya24bmktpclyfhxc2ju";

        allQuestions[31].content = "Do emotions or logic guide better decisions?";
        allQuestions[31].answers = new string[](2);
        allQuestions[31].answers[0] = "Emotions"; allQuestions[31].answers[1] = "Logic";
        allQuestions[31].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeidncahyak4kqyzey4nbjekn27u32vmahy65l3apqsgbav4mkfmu44";

        allQuestions[32].content = "Is it easier to forgive yourself or others?";
        allQuestions[32].answers = new string[](2);
        allQuestions[32].answers[0] = "Yourself"; allQuestions[32].answers[1] = "Others";
        allQuestions[32].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeiay2nv3yjuinymu6huwtm4kejaqdbfznppjnkoaiznha4z7r73buu";

        allQuestions[33].content = "Is love more about passion or companionship?";
        allQuestions[33].answers = new string[](2);
        allQuestions[33].answers[0] = "Passion"; allQuestions[33].answers[1] = "Companionship";
        allQuestions[33].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeig324mjg2b3i6rxiihorji74lsdkd56nfbuhrxwnp4vzf3lncresi";

        allQuestions[34].content = "Is it better to flee or fight when in danger?";
        allQuestions[34].answers = new string[](2);
        allQuestions[34].answers[0] = "Flee"; allQuestions[34].answers[1] = "Fight";
        allQuestions[34].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeied6cg6rdpn7o74wlooyxsp3pejbm7lih53452z2u3vwatsoiipfm";

        allQuestions[35].content = "Is creativity more a result of talent or hard work?";
        allQuestions[35].answers = new string[](2);
        allQuestions[35].answers[0] = "Talent"; allQuestions[35].answers[1] = "Hard work";
        allQuestions[35].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeieetiujrreb7vehfaf3v6n63cqh6qcwgdahnaev6qd6pxmaaf3ewm";

        allQuestions[36].content = "Catchy song stuck in your head or bad haircut?";
        allQuestions[36].answers = new string[](2);
        allQuestions[36].answers[0] = "Song"; allQuestions[36].answers[1] = "Haircut";
        allQuestions[36].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeibycou66kslkuieji375ex6nf46qm4vixsnrer6mxagbuksgta3a4";

        allQuestions[37].content = "Only eat pizza or chocolate forever?";
        allQuestions[37].answers = new string[](2);
        allQuestions[37].answers[0] = "Pizza"; allQuestions[37].answers[1] = "Chocolate";
        allQuestions[37].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeicnmcvlehzuw4ewq5oijmawnmltwyh7uevl73mi7igsrp5a6dvnse";

        allQuestions[38].content = "Talk to animals or speak every language?";
        allQuestions[38].answers = new string[](2);
        allQuestions[38].answers[0] = "Animals"; allQuestions[38].answers[1] = "Languages";
        allQuestions[38].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeib3ytzgp5wshto2iebvnqbfzdm2t4mvrl7ayg77pizsolgdj24w6a";

        allQuestions[39].content = "Fight a horse-sized duck or 100 duck-sized horses?";
        allQuestions[39].answers = new string[](2);
        allQuestions[39].answers[0] = "Big duck"; allQuestions[39].answers[1] = "Tiny horses";
        allQuestions[39].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeietkmyihkiord7rvjdcnjom2mahzvqk74o655pkp5ytfb5st7a33q";

        allQuestions[40].content = "Always 10 minutes late or 20 minutes early?";
        allQuestions[40].answers = new string[](2);
        allQuestions[40].answers[0] = "Late"; allQuestions[40].answers[1] = "Early";
        allQuestions[40].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeiddffh2gkyncs7uvnbbmbiqwn7gycgigqsmjgmdhiiv26gsover44";

        allQuestions[41].content = "Invisibility or flying?";
        allQuestions[41].answers = new string[](2);
        allQuestions[41].answers[0] = "Invisibility"; allQuestions[41].answers[1] = "Flying";
        allQuestions[41].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeibipzcp44dqgw52ye3zmmilbhr4eiccnr7i6xumahmnpp4l3ks7rq";

        allQuestions[42].content = "No traffic or no waiting in line?";
        allQuestions[42].answers = new string[](2);
        allQuestions[42].answers[0] = "No traffic"; allQuestions[42].answers[1] = "No lines";
        allQuestions[42].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeiesxzydn36doti3lvizlvqywcsrbpt2hcfj2notdkxunah4efy4hq";

        allQuestions[43].content = "Pause life or rewind it?";
        allQuestions[43].answers = new string[](2);
        allQuestions[43].answers[0] = "Pause"; allQuestions[43].answers[1] = "Rewind";
        allQuestions[43].imgUrl = "https://gateway.pinata.cloud/ipfs/bafybeifacefg4icojfvzsmrftkf37vjev67wj4jtoxgo7iexgk4np5ufba";
    }
}
