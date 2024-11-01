// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {LibBytes, Pointer} from "rain.solmem/lib/LibBytes.sol";
import {LibParseDecimal} from "src/lib/parse/LibParseDecimal.sol";

/// @title TestLibParseDecimalUnsafeDecimalStringToSignedInt
contract TestLibParseDecimalUnsafeDecimalStringToSignedInt is Test {
    using Strings for uint256;
    using LibBytes for bytes;

    function testUnsafeStrToSignedIntRoundTrip(uint256 value, uint8 leadingZerosCount, bool isNeg) external pure {
        value = bound(value, 0, uint256(type(int256).max) + (isNeg ? 1 : 0));
        string memory str = value.toString();

        string memory leadingZeros = new string(leadingZerosCount);
        for (uint8 i = 0; i < leadingZerosCount; i++) {
            bytes(leadingZeros)[i] = "0";
        }

        string memory input = string(abi.encodePacked((isNeg ? "-" : ""), leadingZeros, str));

        (uint256 success, int256 result) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(success, 1);

        if (isNeg) {
            if (result == type(int256).min) {
                assertEq(value, uint256(type(int256).max) + 1);
            } else {
                assertEq(result, -int256(value));
            }
        } else {
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

        (uint256 success,) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(success, 0);
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

        (uint256 success,) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(success, 0);
    }
}
