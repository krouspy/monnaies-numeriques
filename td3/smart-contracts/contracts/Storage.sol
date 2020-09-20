// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Storage {
    uint private value;

    function getValue() view public returns (uint) {
        return value;
    }

    function setValue(uint val) public {
        value = val;
    }
}
