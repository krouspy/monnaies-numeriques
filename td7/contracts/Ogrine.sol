// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./Kamas.sol";

contract Ogrine {
    address public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping(address => uint256) public accountToDepositedKamas;
    mapping(address => uint256) public accountToDepositedETH;

    IUniswapV2Router02 public router;
    Kamas public kamas;

    constructor(Kamas _kamas) public {
        router = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        kamas = _kamas;
    }

    function deposit(uint256 amount) public {
        kamas.transferFrom(msg.sender, address(this), amount);
    }

    function approveRouter(uint256 amount) public {
        kamas.approve(UNISWAP_ROUTER_ADDRESS, amount);
    }

    function depositToPool(
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountEthMin
    ) public payable {
        // what happens when amount deposited < amountTokenDesired?
        accountToDepositedKamas[msg.sender] += amountTokenDesired;
        // what happens when amount deposited < msg.value?
        accountToDepositedETH[msg.sender] += msg.value;

        // just for simplicity
        uint256 deadline = block.timestamp + 30;

        router.addLiquidityETH{ value: msg.value}(
            address(kamas),
            amountTokenDesired,
            amountTokenMin,
            amountEthMin,
            msg.sender,
            deadline
        );
    }

    function withdrawFromPool(
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountEthMin
    ) public {
        // what happens when amount withdrew < liquidity?
        accountToDepositedKamas[msg.sender] -= liquidity;
        // what happens when amount withdrew > amountEthMin?
        accountToDepositedETH[msg.sender] -= amountEthMin;

        // just for simplicity
        uint256 deadline = block.timestamp + 30;

        router.removeLiquidityETH(
            address(kamas),
            liquidity,
            amountTokenMin,
            amountEthMin,
            msg.sender,
            deadline
        );
    }
}