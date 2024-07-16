// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {

    constructor() ERC20("USDC", "USDC") {
        _mint(msg.sender, 10000*10**6);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mintToken(uint256 amount) public returns(uint256){
        _mint(msg.sender, amount);
        return amount;
    }

    function mint(address to, uint256 amount) public returns(uint256) {
        _mint(to, amount);
        return amount;
    }
}
