// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {StringSlicer} from "../src/Libraries/StringSlicer.sol";

contract ContractTest is Test {
    function testPad() external {
        // Left
        string memory str = "test";
        string memory res = pad(true, str, 10);
        assertEq(bytes(res).length, 10);
        assertEq(keccak256(abi.encodePacked(res)), keccak256(abi.encodePacked("      test")));
        // Right
        res = pad(false, str, 10);
        assertEq(bytes(res).length, 10);
        assertEq(keccak256(abi.encodePacked(res)), keccak256(abi.encodePacked("test      ")));
    }

    function testPadUnicode() external {
        string memory str = unicode""; // 3 bytes, source https://mothereff.in/byte-counter#%EE%80%B1
        // Left
        string memory res = pad(true, str, 10);
        assertEq(bytes(res).length, 10);
        assertEq(keccak256(abi.encodePacked(res)), keccak256(abi.encodePacked(unicode"       ")));
        // Right
        res = pad(false, str, 10);
        assertEq(bytes(res).length, 10);
        assertEq(keccak256(abi.encodePacked(res)), keccak256(abi.encodePacked(unicode"       ")));
    }

    // Ellipsis is 3 bytes, Capsules' Juicebox is 3 bytes
    function testUnicodeByteCount() external {
        assertEq(bytes(unicode"…").length, 3);
        assertEq(bytes(unicode"").length, 3);
    }

    // Anticipates 2 extra bytes bc unicode ellipsis is 3 bytes
    function testPadShorten() external {
        string memory str = "testing a string that's longer than the target";
        // Left
        string memory res = pad(true, str, 10);
        console.log(res);
        assertEq(bytes(res).length, 12);
        assertEq(keccak256(abi.encodePacked(res)), keccak256(abi.encodePacked(unicode"testing a…")));
        // Right
        res = pad(false, str, 10);
        console.log(res);
        assertEq(bytes(res).length, 12);
        assertEq(keccak256(abi.encodePacked(res)), keccak256(abi.encodePacked(unicode"testing a…")));
    }

    // Anticipates 2 extra bytes bc unicode Capsules' Juicebox is 3 bytes
    function testPadShortenUnicode() external {
        string memory str = unicode" testing a string that's longer than the target";
        // Left
        string memory res = pad(true, str, 10);
        console.log(res);
        assertEq(bytes(res).length, 12);
        assertEq(keccak256(abi.encodePacked(res)), keccak256(abi.encodePacked(unicode" testi…")));
        // Right
        res = pad(false, str, 10);
        console.log(res);
        assertEq(bytes(res).length, 12);
        assertEq(keccak256(abi.encodePacked(res)), keccak256(abi.encodePacked(unicode" testi…")));
    }

    // Pad is an internal fn, so it has to be copied here to test it
    /**
     * @notice Transform strings to target length by abbreviation or left padding with spaces.
     * @dev Shortens long strings to 13 characters including an ellipsis and adds left padding spaces to short strings. Allows variable target length to account for strings that have unicode characters that are longer than 1 byte but only take up 1 character space.
     * @param left True adds padding to the left of the passed string, and false adds padding to the right
     * @param str The string to transform
     * @param targetLength The length of the string to return
     * @return string The transformed string
     */
    function pad(bool left, string memory str, uint256 targetLength) internal pure returns (string memory) {
        uint256 length = bytes(str).length;

        // If string is already target length, return it
        if (length == targetLength) {
            return str;
        }

        // If string is longer than target length, abbreviate it and add an ellipsis
        if (length > targetLength) {
            str = string.concat(
                StringSlicer.slice(str, 0, targetLength - 1), // Abbreviate to 1 character less than target length
                unicode"…" // And add an ellipsis
            );
            return str;
        }

        // If string is shorter than target length, pad it on the left or right as specified
        string memory padding;
        uint256 _paddingToAdd = targetLength - length;
        for (uint256 i; i < _paddingToAdd; ) {
            padding = string.concat(padding, " ");
            unchecked {
                ++i;
            }
        }
        str = left ? string.concat(padding, str) : string.concat(str, padding); // Left/right check
        return str;
    }
}
