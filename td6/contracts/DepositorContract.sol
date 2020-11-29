pragma solidity ^0.6.0;

import "./ERC20TD.sol";
import "./DepositorToken.sol";

contract DepositorContract {
    event ClaimerAdded(address indexed account);
    event Redeem(address indexed claimer, uint256 indexed amount);

    ERC20TD private _erc20;

    address[] private _claimers;
    DepositorToken private _depositorToken;

    constructor(ERC20TD erc20, DepositorToken depositorToken) public  {
        _erc20 = erc20;
        _depositorToken = depositorToken;
    }

    function getClaimers() public view returns (address[] memory) {
        return _claimers;
    }

    function claimTokens() public {
        _erc20.claimTokens();
        _depositorToken.mint(msg.sender, 1000);
        _addClaimer(msg.sender);
    }

    // require having called approve(DepositorContract, amount)
    function depositMyTokens(uint256 amount) public {
        require(_contains(msg.sender), "DepositorContract: caller must have claimed once");

        _depositorToken.transferFrom(msg.sender, address(this), amount);
    }

    function collectMyTokens(uint256 amount) public {
        require(_contains(msg.sender), "DepositorContract: caller must have claimed once");

        _depositorToken.burnFrom(address(this), amount);

        emit Redeem(msg.sender, amount);
    }

    function _addClaimer(address claimer) private {
        if (!_contains(claimer)) {
            _claimers.push(claimer);

            emit ClaimerAdded(claimer);
        }
    }

    function _contains(address account) private view returns (bool) {
        bool result;

        for (uint256 i = 0; i < _claimers.length; i++) {
            if (_claimers[i] == account) {
                result = true;
                break;
            }
        }

        return result;
    }
}