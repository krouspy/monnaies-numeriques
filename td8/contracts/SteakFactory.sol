// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Steak.sol";

contract SteakFactory is Ownable {
    Steak private steak;

    mapping(address => bool) public whitelist;

    bytes32 public constant hashToSignToClaimAToken = "Miam Miam les steaks";

    constructor(Steak _steak) public {
        steak = _steak;
        whitelist[msg.sender] = true;
    }

    function claimToken(bytes memory _signature, uint256 tokenId) public {
        bytes32 _hash = keccak256(abi.encode(hashToSignToClaimAToken, tokenId));

        require(signerIsWhitelisted(_hash, _signature), "claimToken: signer is not whitelisted or signature invalid");

        address signerAddress = extractAddress(_hash, _signature);
        require(signerAddress != msg.sender, "claimToken: Minter and Signer must be different");

        steak.mint(signerAddress);
    }

    function getWhitelisted() public returns (bool) {
        require(!whitelist[msg.sender], "getWhitelisted: caller already whitelisted");

        whitelist[msg.sender] = true;

        return true;
    }

    function signerIsWhitelisted(bytes32 _hash, bytes memory _signature) internal view returns (bool){
        bytes32 r;
        bytes32 s;
        uint8 v;
        // Check the signature length
        if (_signature.length != 65) {
            return false;
        }
        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return false;
        } else {
            // solium-disable-next-line arg-overflow
            return whitelist[ecrecover(keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            ), v, r, s)];
        }
    }

    function extractAddress(bytes32 _hash, bytes memory _signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        // Check the signature length
        if (_signature.length != 65) {
            return address(0);
        }
        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return address(0);
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
                ), v, r, s);
        }
    }
}
