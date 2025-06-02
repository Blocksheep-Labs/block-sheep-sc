// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract BlockSheepPayments is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public immutable UNDERLYING;

    constructor(
        address _underlying,
        address owner
    ) Ownable(owner) {
        UNDERLYING = IERC20(_underlying);
    }

    mapping (uint256 => mapping(address => uint256)) public payments;

    event PaymentReceived(address indexed user, uint256 raceId, uint256 amount, uint256 currentAmount);
    event PaymentSend(address indexed user, uint256 amount);

    function pay(
        uint256 amount,
        uint256 raceId
    ) external {
        require(amount > 0, "Amount to buy must be greater than zero");

        UNDERLYING.safeTransferFrom(msg.sender, address(this), amount);

        payments[raceId][msg.sender] += amount;

        emit PaymentReceived(
            msg.sender,
            raceId,
            amount,
            payments[raceId][msg.sender]
        );
    }

    function send(
        uint256 amount,
        address to
    ) external onlyOwner {
        require(amount > 0, "Amount to send must be greater than zero");

        UNDERLYING.safeTransferFrom(address(this), to, amount);

        emit PaymentSend(to, amount);
    }
}
