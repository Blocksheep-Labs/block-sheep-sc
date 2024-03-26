pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import {BlockSheep} from "../src/BlockSheep.sol";

contract DeployBlockSheep is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new BlockSheep(
            0xD50a445Fb56b8Dacd5B73aa8D472Ee4bD9e21b44,
            vm.addr(deployerPrivateKey),
            10e6
        );
        vm.stopBroadcast();
    }
}
