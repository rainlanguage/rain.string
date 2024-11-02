// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {LibBytes, Pointer} from "rain.solmem/lib/LibBytes.sol";
import {LibParseDecimal} from "src/lib/parse/LibParseDecimal.sol";
import {ParseEmptyDecimalString, ParseDecimalOverflow} from "src/error/ErrParse.sol";

/// @title TestLibParseDecimalUnsafeDecimalStringToInt
/// @dev Test `TestLibParseDecimal.unsafeDecimalStringToInt`
contract TestLibParseDecimalUnsafeDecimalStringToInt is Test {
    using Strings for uint256;
    using LibBytes for bytes;

    /// Test that when start is greater than or equal to end, the function
    /// fails.
    function testUnsafeDecimalStrToIntEmpty(uint256 start, uint256 end) external pure {
        start = bound(start, end, type(uint256).max);
        (bytes4 errorSelector, uint256 result) = LibParseDecimal.unsafeDecimalStringToInt(start, end);
        assertEq(errorSelector, ParseEmptyDecimalString.selector);
        assertEq(result, 0);
    }

    /// Test round tripping strings through the unsafeStrToInt function.
    function testUnsafeDecimalStrToIntRoundTrip(uint256 value, uint8 leadingZerosCount) external pure {
        string memory str = value.toString();

        string memory leadingZeros = new string(leadingZerosCount);
        for (uint8 i = 0; i < leadingZerosCount; i++) {
            bytes(leadingZeros)[i] = "0";
        }

        string memory input = string(abi.encodePacked(leadingZeros, str));

        (bytes4 errorSelector, uint256 result) = LibParseDecimal.unsafeDecimalStringToInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );

        assertEq(errorSelector, bytes4(0));
        assertEq(result, value);
    }

    /// Test very large number overflow.
    function testUnsafeDecimalStrToIntOverflowVeryLarge(uint256 high, uint256 low, uint8 leadingZerosCount)
        external
        pure
    {
        vm.assume(high > 0);
        low = bound(low, 1 << 0xFF, type(uint256).max);
        string memory strHigh = high.toString();
        string memory strLow = low.toString();

        string memory leadingZeros = new string(leadingZerosCount);
        for (uint8 i = 0; i < leadingZerosCount; i++) {
            bytes(leadingZeros)[i] = "0";
        }

        string memory input = string(abi.encodePacked(strHigh, strLow));

        (bytes4 errorSelector, uint256 result) = LibParseDecimal.unsafeDecimalStringToInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );

        assertEq(errorSelector, ParseDecimalOverflow.selector);
        assertEq(result, 0);
    }
}
