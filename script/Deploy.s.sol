pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import {Blacksheep} from "../src/Blacksheep.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new Blacksheep();
        vm.stopBroadcast();
    }
}
