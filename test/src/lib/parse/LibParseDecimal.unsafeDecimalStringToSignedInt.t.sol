// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {LibBytes, Pointer} from "rain.solmem/lib/LibBytes.sol";
import {LibParseDecimal} from "src/lib/parse/LibParseDecimal.sol";
import {ParseDecimalOverflow} from "src/error/ErrParse.sol";

/// @title TestLibParseDecimalUnsafeDecimalStringToSignedInt
contract TestLibParseDecimalUnsafeDecimalStringToSignedInt is Test {
    using Strings for uint256;
    using LibBytes for bytes;

    function checkUnsafeStrToSignedInt(string memory input, int256 expected) internal pure {
        (bytes4 errorSelector, int256 result) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(errorSelector, bytes4(0));
        assertEq(result, expected);
    }

    function testUnsafeStrToSignedIntExamples() external pure {
        checkUnsafeStrToSignedInt("123", 123);
        checkUnsafeStrToSignedInt("-123", -123);
        checkUnsafeStrToSignedInt("0", 0);
        checkUnsafeStrToSignedInt("-0", 0);
        checkUnsafeStrToSignedInt("123456789012345678901234567890", 123456789012345678901234567890);
        checkUnsafeStrToSignedInt("-123456789012345678901234567890", -123456789012345678901234567890);
        checkUnsafeStrToSignedInt(
            "57896044618658097711785492504343953926634992332820282019728792003956564819967", type(int256).max
        );
        checkUnsafeStrToSignedInt(
            "-57896044618658097711785492504343953926634992332820282019728792003956564819968", type(int256).min
        );
    }

    function testUnsafeStrToSignedIntRoundTrip(uint256 value, uint8 leadingZerosCount, bool isNeg) external pure {
        value = bound(value, 0, uint256(type(int256).max) + (isNeg ? 1 : 0));
        string memory str = value.toString();

        string memory leadingZeros = new string(leadingZerosCount);
        for (uint8 i = 0; i < leadingZerosCount; i++) {
            bytes(leadingZeros)[i] = "0";
        }

        string memory input = string(abi.encodePacked((isNeg ? "-" : ""), leadingZeros, str));

        (bytes4 errorSelector, int256 result) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(errorSelector, bytes4(0));

        if (isNeg) {
            if (result == type(int256).min) {
                assertEq(value, uint256(type(int256).max) + 1);
            } else {
                // forge-lint: disable-next-line(unsafe-typecast)
                assertEq(result, -int256(value));
            }
        } else {
            // forge-lint: disable-next-line(unsafe-typecast)
            assertEq(result, int256(value));
        }
    }

    /// Test positive overflow.
    function testUnsafeStrToSignedIntOverflowPositive(uint256 value, uint8 leadingZerosCount) external pure {
        value = bound(value, uint256(type(int256).max) + 1, type(uint256).max);
        string memory str = value.toString();

        string memory leadingZeros = new string(leadingZerosCount);
        for (uint8 i = 0; i < leadingZerosCount; i++) {
            bytes(leadingZeros)[i] = "0";
        }

        string memory input = string(abi.encodePacked(leadingZeros, str));

        (bytes4 errorSelector,) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(errorSelector, ParseDecimalOverflow.selector);
    }

    /// Test negative overflow.
    function testUnsafeStrToSignedIntOverflowNegative(uint256 value, uint8 leadingZerosCount) external pure {
        value = bound(value, uint256(type(int256).max) + 2, type(uint256).max);
        string memory str = value.toString();

        string memory leadingZeros = new string(leadingZerosCount);
        for (uint8 i = 0; i < leadingZerosCount; i++) {
            bytes(leadingZeros)[i] = "0";
        }

        string memory input = string(abi.encodePacked("-", leadingZeros, str));

        (bytes4 errorSelector,) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(errorSelector, ParseDecimalOverflow.selector);
    }
}
