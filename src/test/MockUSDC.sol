// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract MockUSDC is ERC20Mock {
    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
