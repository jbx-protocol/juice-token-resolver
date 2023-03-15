// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {StringSlicer} from "../src/Libraries/StringSlicer.sol";

contract ContractTest is Test {
    
    function testSlice()external{
        string memory str = "012345";
        assertEq(StringSlicer.slice(str, 0, 5), "01234");
        str = "012345";
        assertEq(StringSlicer.slice(str, 1, 6), "12345");
    }
}