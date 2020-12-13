// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Steak is ERC721, Ownable {
    event MinterAdded(address indexed account);

    mapping (address => bool) public minters;
    uint256 public nextTokenId;

    constructor() public ERC721("Steak", "STK") {
        minters[msg.sender] = true;
    }

    function addMinter(address account) public onlyOwner returns (bool) {
        require(!minters[account], "Steak: address is already whitelisted");

        minters[account] = true;
        emit MinterAdded(account);

        return true;
    }

    function mint(address _account, uint256 _tokenId) public returns (bool) {
        require(minters[msg.sender], "Steak: caller must be whitelisted");

        _safeMint(_account, _tokenId);
        nextTokenId++;

        return true;
    }
}
