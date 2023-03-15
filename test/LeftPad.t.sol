// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {StringSlicer} from "../src/Libraries/StringSlicer.sol";

contract ContractTest is Test {

    function testLeftPadShorter() external {
        string memory str = "test";
        string memory res = leftPad(str, 10);
        assertEq(bytes(res).length, 10);
    }

    function testLeftPadShorterUnicode() external {
        string memory str = unicode"";
        string memory res = leftPad(str, 10);
        assertEq(bytes(res).length, 10);
    }

    // Ellipsis is 3 bytes
    // Capsules' Juicebox is
    function testUnicodeByteCount() external {
        // console.log(bytes(unicode'…').length);
        assertEq(bytes(unicode"…").length, 3);
        assertEq(bytes(unicode"").length, 3);
    }

    // Anticipates 2 extra bytes bc unicode ellipsis is 3 bytes
    function testLeftPadLonger() external {
        string memory str = "testing a very long string";
        string memory res = leftPad(str, 10);
        console.log(res);
        assertEq(bytes(res).length, 12);
    }

    // Anticipates 2 extra bytes bc unicode Capsules' Juicebox is 3 bytes
    function testLeftPadLongerUnicode() external {
        string memory str = unicode" testing a very long string";
        string memory res = leftPad(str, 10);
        assertEq(bytes(res).length, 12);
    }

    // Copied leftPad fn here bc it's an internal fn
    function leftPad(string memory str, uint256 targetLength)
        internal
        view
        returns (string memory)
    {
        uint256 length = bytes(str).length;
        if (length > targetLength) {
            // Shorten strings strings longer than target length
            str = string(
                abi.encodePacked(
                    StringSlicer.slice(str, 0, targetLength - 1),
                    unicode"…"
                )
            ); // Shortens to 1 character less than target length and adds an ellipsis unicode character
        } else {
            // Pad strings shorter than target length
            string memory padding;
            for (uint256 i = 0; i < targetLength - length; i++) {
                padding = string(abi.encodePacked(padding, " "));
            }
            str = string.concat(padding, str);
        }
        return str;
    }
}
