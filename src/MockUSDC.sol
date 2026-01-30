// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {

    constructor() ERC20("USDC", "USDC") {
        _mint(msg.sender, 10000*10**6);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount, bool withETH) public returns(uint256) {
         if (withETH) {
            uint256 ethAmount = 0.0012 ether;
            require(address(this).balance >= ethAmount, "Insufficient ETH in contract");
            payable(to).transfer(ethAmount);
        }

        _mint(to, amount);
        return amount;
    }

    function burn(address user, uint256 amount) public returns(uint256) {
        _burn(user, amount);
        return amount;
    }

    receive() external payable {
        // This function is executed when a contract receives plain Ether (without data)
    }
}
