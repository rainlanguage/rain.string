// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {Strings} from "@openzeppelin-contracts-5.6.1/utils/Strings.sol";
import {LibBytes, Pointer} from "rain-solmem-0.1.26/src/lib/LibBytes.sol";
import {LibParseDecimal} from "src/lib/parse/LibParseDecimal.sol";
import {ParseEmptyDecimalString, ParseDecimalOverflow, ZeroStringStartPointer} from "src/error/ErrParse.sol";

/// @title TestLibParseDecimalUnsafeDecimalStringToSignedInt
contract TestLibParseDecimalUnsafeDecimalStringToSignedInt is Test {
    using Strings for uint256;
    using LibBytes for bytes;

    function externalTestZeroStringStartPointer(uint256 end) external pure {
        LibParseDecimal.unsafeDecimalStringToSignedInt(0, end);
    }

    function testExternalTestZeroStringStartPointer(uint256 end) external {
        vm.assume(end > 0);
        vm.expectRevert(abi.encodeWithSelector(ZeroStringStartPointer.selector));
        this.externalTestZeroStringStartPointer(end);
    }

    /// Test that when start is greater than or equal to end, the signed
    /// conversion returns the empty string error selector and a zero value.
    /// The negative sign check reads memory at start, so start is bound to
    /// pointers that can be read without excessive memory expansion.
    function testUnsafeStrToSignedIntEmpty(uint256 start, uint256 end) external pure {
        end = bound(end, 0, type(uint16).max);
        start = bound(start, end, type(uint16).max);
        (bytes4 errorSelector, int256 result) = LibParseDecimal.unsafeDecimalStringToSignedInt(start, end);
        assertEq(errorSelector, ParseEmptyDecimalString.selector);
        assertEq(result, 0);
    }

    /// Test that a lone negative sign is an empty decimal string.
    function testUnsafeStrToSignedIntNegOnly() external pure {
        string memory input = "-";
        (bytes4 errorSelector, int256 result) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(errorSelector, ParseEmptyDecimalString.selector);
        assertEq(result, 0);
    }

    /// Test that unsigned overflow from the inner decimal parse propagates
    /// through the signed conversion with a zero value.
    function testUnsafeStrToSignedIntInnerOverflowPropagates() external pure {
        // uint256 max + 1 does not fit the inner unsigned parse.
        string memory input = "115792089237316195423570985008687907853269984665640564039457584007913129639936";
        (bytes4 errorSelector, int256 result) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(errorSelector, ParseDecimalOverflow.selector);
        assertEq(result, 0);

        input = "-115792089237316195423570985008687907853269984665640564039457584007913129639936";
        (errorSelector, result) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(errorSelector, ParseDecimalOverflow.selector);
        assertEq(result, 0);
    }

    /// Test the exact overflow boundaries: int256 max + 1 overflows the
    /// positive case and 2^255 + 1 overflows the negative case. Both return
    /// a zero value beside the selector.
    function testUnsafeStrToSignedIntBoundaryOverflow() external pure {
        // int256 max + 1 == 2^255.
        string memory input = "57896044618658097711785492504343953926634992332820282019728792003956564819968";
        (bytes4 errorSelector, int256 result) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(errorSelector, ParseDecimalOverflow.selector);
        assertEq(result, 0);

        // -(2^255 + 1).
        input = "-57896044618658097711785492504343953926634992332820282019728792003956564819969";
        (errorSelector, result) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(errorSelector, ParseDecimalOverflow.selector);
        assertEq(result, 0);
    }

    /// Test that garbage input reaching the negative overflow path returns a
    /// zero value beside the selector. A double negative sign leaves the inner
    /// unsigned parse reading the second sign as a digit, which lands in the
    /// negative overflow branch.
    function testUnsafeStrToSignedIntGarbageOverflowZeroValue() external pure {
        string memory input = "--5";
        (bytes4 errorSelector, int256 result) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(errorSelector, ParseDecimalOverflow.selector);
        assertEq(result, 0);
    }

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

        (bytes4 errorSelector, int256 result) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(errorSelector, ParseDecimalOverflow.selector);
        assertEq(result, 0);
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

        (bytes4 errorSelector, int256 result) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(errorSelector, ParseDecimalOverflow.selector);
        assertEq(result, 0);
    }
}
