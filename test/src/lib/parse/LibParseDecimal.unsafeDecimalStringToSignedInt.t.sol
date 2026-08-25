// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.2/src/Test.sol";
import {Strings} from "@openzeppelin-contracts-5.7.0/utils/Strings.sol";
import {LibBytes, Pointer} from "rain-solmem-0.1.26/src/lib/LibBytes.sol";
import {LibParseDecimal} from "src/lib/parse/LibParseDecimal.sol";
import {LibParseDecimalSlow} from "test/lib/parse/LibParseDecimalSlow.sol";
import {
    ParseEmptyDecimalString,
    ParseDecimalOverflow,
    ParseInvalidDecimalChar,
    ZeroStringStartPointer
} from "src/error/ErrParse.sol";

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

    /// Writes a negative sign byte into scratch space at address zero before
    /// calling the signed conversion with a zero start pointer, so the byte
    /// the negative sign check would read at address zero is 0x2D.
    function externalTestZeroStringStartPointerScratchSign(uint256 end) external pure {
        assembly ("memory-safe") {
            mstore8(0, 0x2D)
        }
        LibParseDecimal.unsafeDecimalStringToSignedInt(0, end);
    }

    /// Test that a zero start pointer reverts even when the byte at memory
    /// address zero is the negative sign character. The internal library call
    /// shares the external helper's memory, so the scratch write is visible
    /// to the conversion.
    function testExternalTestZeroStringStartPointerScratchSign(uint256 end) external {
        end = bound(end, 1, type(uint16).max);
        vm.expectRevert(abi.encodeWithSelector(ZeroStringStartPointer.selector));
        this.externalTestZeroStringStartPointerScratchSign(end);
    }

    /// Test that an empty region starting at pointer zero is reported as an
    /// empty decimal string rather than a zero start pointer, even when the
    /// byte at memory address zero is the negative sign character. This
    /// matches `unsafeDecimalStringToInt`, which checks emptiness first.
    function testUnsafeStrToSignedIntZeroStartEmpty() external pure {
        assembly ("memory-safe") {
            mstore8(0, 0x2D)
        }
        (bytes4 errorSelector, int256 result) = LibParseDecimal.unsafeDecimalStringToSignedInt(0, 0);
        assertEq(errorSelector, ParseEmptyDecimalString.selector);
        assertEq(result, 0);
    }

    /// Test that when start is greater than or equal to end, the signed
    /// conversion returns the empty string error selector and a zero value.
    /// The empty check returns before the negative sign check, so no memory
    /// is read and the full pointer domain is safe to fuzz.
    function testUnsafeStrToSignedIntEmpty(uint256 start, uint256 end) external pure {
        start = bound(start, end, type(uint256).max);
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

    /// Test that a double negative sign yields `ParseInvalidDecimalChar` and
    /// a zero value. Only the first sign is consumed as a negative sign; the
    /// second reaches the inner unsigned parse, which rejects it as an
    /// invalid decimal character.
    function testUnsafeStrToSignedIntDoubleNegInvalidChar() external pure {
        string memory input = "--5";
        (bytes4 errorSelector, int256 result) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(errorSelector, ParseInvalidDecimalChar.selector);
        assertEq(result, 0);
    }

    /// Test that `ParseInvalidDecimalChar` from the inner unsigned parse
    /// propagates through the signed conversion with a zero value, for
    /// invalid bytes with and without a leading negative sign.
    function testUnsafeStrToSignedIntInvalidCharPropagates() external pure {
        checkUnsafeStrToSignedIntInvalid("-1a");
        checkUnsafeStrToSignedIntInvalid(" 1");
        checkUnsafeStrToSignedIntInvalid("+5");
        checkUnsafeStrToSignedIntInvalid("-1.5");
    }

    /// Test the sign entry edges. `+` is not a recognized sign, so it reaches
    /// the inner unsigned parse and classifies as an invalid decimal
    /// character. A consumed leading `-` still subjects every byte after it to
    /// the digit check, so an invalid byte after the sign is invalid too.
    function testUnsafeStrToSignedIntSignEdges() external pure {
        checkUnsafeStrToSignedIntInvalid("+5");
        checkUnsafeStrToSignedIntInvalid("-a5");
    }

    function checkUnsafeStrToSignedIntInvalid(string memory input) internal pure {
        (bytes4 errorSelector, int256 result) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(errorSelector, ParseInvalidDecimalChar.selector);
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

    function checkUnsafeStrToSignedIntAgainstReference(bytes memory data) internal pure {
        (bytes4 slowSelector, int256 slowValue) = LibParseDecimalSlow.decimalStringToSignedIntSlow(data);
        (bytes4 errorSelector, int256 result) = LibParseDecimal.unsafeDecimalStringToSignedInt(
            Pointer.unwrap(data.dataPointer()), Pointer.unwrap(data.endDataPointer())
        );
        assertEq(errorSelector, slowSelector);
        assertEq(result, slowValue);
    }

    /// Test that the signed conversion agrees with the naive reference
    /// implementation on both the selector and the value for arbitrary bytes.
    function testUnsafeStrToSignedIntReference(bytes memory data) external pure {
        checkUnsafeStrToSignedIntAgainstReference(data);
    }

    /// Test that the signed conversion agrees with the naive reference
    /// implementation on both the selector and the value for digit-dense
    /// strings up to 100 digits, crossing the 77-character accumulation
    /// window, with an optional leading `-` or `+` and one arbitrary byte
    /// overwriting a digit at any position (or not at all when the overwrite
    /// position lands past the end).
    function testUnsafeStrToSignedIntReferenceLong(
        uint256 seed,
        uint256 length,
        uint256 overwritePosition,
        uint8 overwriteByte,
        uint256 signMode
    ) external pure {
        length = bound(length, 1, 100);
        bytes memory digits = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            // forge-lint: disable-next-line(unsafe-typecast)
            digits[i] = bytes1(uint8(0x30 + uint256(keccak256(abi.encodePacked(seed, i))) % 10));
        }
        overwritePosition = bound(overwritePosition, 0, length);
        if (overwritePosition < length) {
            digits[overwritePosition] = bytes1(overwriteByte);
        }

        // 0 is unsigned, 1 is a leading negative sign, 2 is a leading `+`,
        // which is not a sign and classifies as an invalid decimal character.
        signMode = bound(signMode, 0, 2);
        bytes memory data = digits;
        if (signMode == 1) {
            data = abi.encodePacked("-", digits);
        } else if (signMode == 2) {
            data = abi.encodePacked("+", digits);
        }
        checkUnsafeStrToSignedIntAgainstReference(data);
    }

    /// Test that the signed conversion agrees with the naive reference
    /// implementation across a window of magnitudes straddling both signed
    /// range boundaries, with and without a leading negative sign. The window
    /// covers `type(int256).max` and its neighbors on the positive side and
    /// `2^255` and its neighbors on the negative side, so an off-by-one on
    /// either bound disagrees with the reference somewhere in the sweep.
    function testUnsafeStrToSignedIntReferenceBoundary() external pure {
        uint256 boundMagnitude = uint256(type(int256).max);
        for (uint256 magnitude = boundMagnitude - 2; magnitude <= boundMagnitude + 3; magnitude++) {
            string memory str = magnitude.toString();
            checkUnsafeStrToSignedIntAgainstReference(bytes(str));
            checkUnsafeStrToSignedIntAgainstReference(abi.encodePacked("-", str));
        }
    }
}
