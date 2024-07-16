pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import {BlockSheep} from "../src/BlockSheep.sol";

contract DeployBlockSheep is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new BlockSheep(
            0x5D2c14A4180A2268cd24460BEca96713ff3Ab2a2,
            vm.addr(deployerPrivateKey),
            10e6
        );
        vm.stopBroadcast();
    }
}
