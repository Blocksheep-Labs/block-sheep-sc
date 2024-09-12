pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import {MockUSDC} from "src/MockUSDC.sol";

contract MintMockUSDC is Script {
    MockUSDC internal usdc = MockUSDC(0x74C33b399BF11e47F8eBa6A93e06c46871D9Cd0c);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        usdc.mint(0x8292250B770D078B4C7FeA1fD044488817085cfC, 1000*10**6);

        vm.stopBroadcast();
    }
}
