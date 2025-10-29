// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Script.sol";
import {BlockSheepPayments} from "../src/BlockSheepPayments.sol";


contract WithdrawUSDC is Script {
    function run(
        address paymentsAddress,
        address withdrawTo,
        uint256 amount
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        BlockSheepPayments blsp = BlockSheepPayments(paymentsAddress);
        blsp.send(amount, withdrawTo);

        vm.stopBroadcast();
    }
}

// 1: 0x2940d1239c3122F0e316d2af923e7A62d700A5c4
// 2: withdraw to address
// 3: 1 USDC is 1.000.000 (10**6)


