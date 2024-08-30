pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import {MockUSDC} from "src/MockUSDC.sol";

contract MintMockUSDC is Script {
    MockUSDC internal usdc = MockUSDC(0x74C33b399BF11e47F8eBa6A93e06c46871D9Cd0c);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        usdc.mint(0x384F0db13B415ED245d65a729f039CF5734BfE14, 1000*10**6);

        vm.stopBroadcast();
    }
}
