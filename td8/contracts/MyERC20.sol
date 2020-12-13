// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyERC20 is ERC20, Ownable {
    mapping (address => bool) public whitelist;

    constructor() public ERC20("MyERC20", "ERC") { }

    function manageWhitelist(address account, bool isWhitelisted) public onlyOwner {
        whitelist[account] = isWhitelisted;
    }

    // must whitelist BoucerProxy
    function mint(address _account, uint256 _amount) public {
        require(whitelist[msg.sender], "Mint: Caller must be whitelisted");

        _mint(_account, _amount);
    }
}
