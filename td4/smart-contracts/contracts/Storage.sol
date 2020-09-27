// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.7.0;

contract Storage {
  string public value;

  function setValue(string memory _value) public {
    value = _value;
  }
}
