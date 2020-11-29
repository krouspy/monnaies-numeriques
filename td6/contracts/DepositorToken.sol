pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DepositorToken is Ownable, ERC20Burnable {
    event ChangeDepositorContractAddress(address indexed from, address indexed to);

    address private _depositorContractAddress;

    constructor() public ERC20("DepositorToken", "DTK") {}

    function getDepositorContractAddress() public view returns (address) {
        return _depositorContractAddress;
    }

    function setDepositorContractAddress(address contractAddress) public onlyOwner {
        _depositorContractAddress = contractAddress;

        emit ChangeDepositorContractAddress(_depositorContractAddress, contractAddress);
    }

    function mint(address account, uint256 amount) public {
        require(_depositorContractAddress != address(0), "DepositorToken: DepositorContract address must not be address(0)");
        require(msg.sender == _depositorContractAddress, "DepositorToken: caller must be DepositorContract");

        _mint(account, amount);
    }
}