// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract  Utils {
    

    function countCharacters(string memory _inputString) public pure returns (uint256) {
        bytes memory stringBytes = bytes(_inputString);
        return stringBytes.length;
    }

    function numberOfBytes(string memory _input) public pure returns (uint256) {
        bytes memory stringBytes = bytes(_input);
        return stringBytes.length;
    } 

    function stringToAddress(string memory _input) public pure returns (address) {
    bytes memory inputBytes = bytes(_input);
    require(inputBytes.length == 42, "Invalid input length");

    uint result = 0;
    uint charValue;

    for (uint i = 2; i < inputBytes.length; i++) {
        uint8 digit = uint8(inputBytes[i]);

        if (digit >= 48 && digit <= 57) {
            charValue = digit - 48;  // '0' to '9'
        } else if (digit >= 65 && digit <= 70) {
            charValue = digit - 55;  // 'A' to 'F'
        } else if (digit >= 97 && digit <= 102) {
            charValue = digit - 87;  // 'a' to 'f'
        } else {
            revert("Invalid character in input");
        }

        result = result * 16 + charValue;
    }

    return (address(uint160(result)));
}



}




