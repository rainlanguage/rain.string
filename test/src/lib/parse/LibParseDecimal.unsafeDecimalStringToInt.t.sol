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

/// @title TestLibParseDecimalUnsafeDecimalStringToInt
/// @dev Test `LibParseDecimal.unsafeDecimalStringToInt`
contract TestLibParseDecimalUnsafeDecimalStringToInt is Test {
    using Strings for uint256;
    using LibBytes for bytes;

    function externalTestZeroStringStartPointer(uint256 end) external pure {
        LibParseDecimal.unsafeDecimalStringToInt(0, end);
    }

    function testExternalTestZeroStringStartPointer(uint256 end) external {
        vm.assume(end > 0);
        vm.expectRevert(abi.encodeWithSelector(ZeroStringStartPointer.selector));
        this.externalTestZeroStringStartPointer(end);
    }

    /// Test that when start is greater than or equal to end, the function
    /// fails.
    function testUnsafeDecimalStrToIntEmpty(uint256 start, uint256 end) external pure {
        start = bound(start, end, type(uint256).max);
        (bytes4 errorSelector, uint256 result) = LibParseDecimal.unsafeDecimalStringToInt(start, end);
        assertEq(errorSelector, ParseEmptyDecimalString.selector);
        assertEq(result, 0);
    }

    /// An empty region starting at pointer zero is reported as an empty
    /// decimal string rather than reverting as a zero start pointer: the
    /// emptiness check runs first. The signed conversion pins the same
    /// ordering.
    function testUnsafeDecimalStrToIntZeroStartEmpty() external pure {
        (bytes4 errorSelector, uint256 result) = LibParseDecimal.unsafeDecimalStringToInt(0, 0);
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

        string memory input = string(abi.encodePacked(leadingZeros, strHigh, strLow));

        (bytes4 errorSelector, uint256 result) = LibParseDecimal.unsafeDecimalStringToInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );

        assertEq(errorSelector, ParseDecimalOverflow.selector);
        assertEq(result, 0);
    }

    /// Test that the exact maximum uint256 value parses, including with
    /// leading zeros.
    function testUnsafeDecimalStrToIntMax(uint8 leadingZerosCount) external pure {
        string memory str = type(uint256).max.toString();

        string memory leadingZeros = new string(leadingZerosCount);
        for (uint8 i = 0; i < leadingZerosCount; i++) {
            bytes(leadingZeros)[i] = "0";
        }

        string memory input = string(abi.encodePacked(leadingZeros, str));

        (bytes4 errorSelector, uint256 result) = LibParseDecimal.unsafeDecimalStringToInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );

        assertEq(errorSelector, bytes4(0));
        assertEq(result, type(uint256).max);
    }

    /// Test that the maximum uint256 value plus one overflows.
    function testUnsafeDecimalStrToIntOverflowMaxPlusOne() external pure {
        bytes memory input = bytes(type(uint256).max.toString());
        // The decimal representation of the max uint256 value ends in a 5, so
        // incrementing the final digit yields the decimal string for 2^256
        // without carrying.
        input[input.length - 1] = "6";

        (bytes4 errorSelector, uint256 result) = LibParseDecimal.unsafeDecimalStringToInt(
            Pointer.unwrap(input.dataPointer()), Pointer.unwrap(input.endDataPointer())
        );

        assertEq(errorSelector, ParseDecimalOverflow.selector);
        assertEq(result, 0);
    }

    /// Test that a 78 digit string with a leading 1 parses when it fits in a
    /// uint256.
    function testUnsafeDecimalStrToIntTenPow77() external pure {
        string memory zeros = new string(77);
        for (uint256 i = 0; i < 77; i++) {
            bytes(zeros)[i] = "0";
        }
        string memory input = string(abi.encodePacked("1", zeros));

        (bytes4 errorSelector, uint256 result) = LibParseDecimal.unsafeDecimalStringToInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );

        assertEq(errorSelector, bytes4(0));
        assertEq(result, 10 ** 77);
    }

    /// Test that a 78 digit string with a leading 2 overflows.
    function testUnsafeDecimalStrToIntOverflowTwoTenPow77() external pure {
        string memory zeros = new string(77);
        for (uint256 i = 0; i < 77; i++) {
            bytes(zeros)[i] = "0";
        }
        string memory input = string(abi.encodePacked("2", zeros));

        (bytes4 errorSelector, uint256 result) = LibParseDecimal.unsafeDecimalStringToInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );

        assertEq(errorSelector, ParseDecimalOverflow.selector);
        assertEq(result, 0);
    }

    /// Test that a 78 digit string with a leading 9 overflows. `9` is the top
    /// of the digit range, so this pins that the 78th-from-last byte check
    /// classifies `9` as an overflowing digit, not as an invalid character.
    function testUnsafeDecimalStrToIntOverflowNineTenPow77() external pure {
        string memory zeros = new string(77);
        for (uint256 i = 0; i < 77; i++) {
            bytes(zeros)[i] = "0";
        }
        string memory input = string(abi.encodePacked("9", zeros));

        (bytes4 errorSelector, uint256 result) = LibParseDecimal.unsafeDecimalStringToInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );

        assertEq(errorSelector, ParseDecimalOverflow.selector);
        assertEq(result, 0);
    }

    /// Test that a nonzero character beyond the 78th digit overflows even when
    /// zeros sit between it and the digits that would otherwise parse. `9` is
    /// the top of the digit range, so the second case pins that the leading
    /// region classifies `9` as an overflowing digit, not as an invalid
    /// character.
    function testUnsafeDecimalStrToIntOverflowNonZeroBeyond78() external pure {
        string memory zeros = new string(77);
        for (uint256 i = 0; i < 77; i++) {
            bytes(zeros)[i] = "0";
        }
        string memory input = string(abi.encodePacked("101", zeros));

        (bytes4 errorSelector, uint256 result) = LibParseDecimal.unsafeDecimalStringToInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );

        assertEq(errorSelector, ParseDecimalOverflow.selector);
        assertEq(result, 0);

        input = string(abi.encodePacked("901", zeros));

        (errorSelector, result) = LibParseDecimal.unsafeDecimalStringToInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );

        assertEq(errorSelector, ParseDecimalOverflow.selector);
        assertEq(result, 0);
    }

    function checkUnsafeStrToIntInvalid(string memory input) internal pure {
        (bytes4 errorSelector, uint256 result) = LibParseDecimal.unsafeDecimalStringToInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(errorSelector, ParseInvalidDecimalChar.selector);
        assertEq(result, 0);
    }

    /// Test that a string exercising every decimal digit parses to its exact
    /// value.
    function testUnsafeDecimalStrToIntAllDigits() external pure {
        string memory input = "9876543210";
        (bytes4 errorSelector, uint256 result) = LibParseDecimal.unsafeDecimalStringToInt(
            Pointer.unwrap(bytes(input).dataPointer()), Pointer.unwrap(bytes(input).endDataPointer())
        );
        assertEq(errorSelector, bytes4(0));
        assertEq(result, 9876543210);
    }

    /// Test that a byte outside `0`-`9` inside the last-77-character window
    /// yields `ParseInvalidDecimalChar` wherever it sits, including the
    /// boundary bytes immediately adjacent to the digit range.
    function testUnsafeDecimalStrToIntInvalidCharInWindow() external pure {
        checkUnsafeStrToIntInvalid(" 1");
        checkUnsafeStrToIntInvalid("1 ");
        checkUnsafeStrToIntInvalid("12 34");
        checkUnsafeStrToIntInvalid("a");
        // 0x2F, one below the `0` byte.
        checkUnsafeStrToIntInvalid("1/1");
        // 0x3A, one above the `9` byte.
        checkUnsafeStrToIntInvalid("1:1");
    }

    /// Test the boundary bytes of the invalid space, each at index 1 of a
    /// three byte string: `/` (0x2F) one below `0`, `:` (0x3A) one above `9`,
    /// 0x80 the lowest high-bit byte, and 0xFF the highest byte. Each yields
    /// `ParseInvalidDecimalChar` and a zero value.
    function testUnsafeDecimalStrToIntBoundaryBytePins() external pure {
        checkUnsafeStrToIntInvalid(string(abi.encodePacked("1", bytes1(0x2F), "1")));
        checkUnsafeStrToIntInvalid(string(abi.encodePacked("1", bytes1(0x3A), "1")));
        checkUnsafeStrToIntInvalid(string(abi.encodePacked("1", bytes1(0x80), "1")));
        checkUnsafeStrToIntInvalid(string(abi.encodePacked("1", bytes1(0xFF), "1")));
    }

    /// Test each boundary byte of the invalid space at exactly the first
    /// position of the region.
    function testUnsafeDecimalStrToIntInvalidByteAtStart() external pure {
        checkUnsafeStrToIntInvalid(string(abi.encodePacked(bytes1(0x2F), "11")));
        checkUnsafeStrToIntInvalid(string(abi.encodePacked(bytes1(0x3A), "11")));
        checkUnsafeStrToIntInvalid(string(abi.encodePacked(bytes1(0x80), "11")));
        checkUnsafeStrToIntInvalid(string(abi.encodePacked(bytes1(0xFF), "11")));
    }

    /// Test each boundary byte of the invalid space at exactly the last
    /// position of the region.
    function testUnsafeDecimalStrToIntInvalidByteAtEnd() external pure {
        checkUnsafeStrToIntInvalid(string(abi.encodePacked("11", bytes1(0x2F))));
        checkUnsafeStrToIntInvalid(string(abi.encodePacked("11", bytes1(0x3A))));
        checkUnsafeStrToIntInvalid(string(abi.encodePacked("11", bytes1(0x80))));
        checkUnsafeStrToIntInvalid(string(abi.encodePacked("11", bytes1(0xFF))));
    }

    /// Test that any byte outside `0`-`9` at any position in an otherwise
    /// valid decimal string yields `ParseInvalidDecimalChar` and a zero value.
    function testUnsafeDecimalStrToIntInvalidCharAnywhere(uint256 value, uint8 invalidByte, uint256 position)
        external
        pure
    {
        vm.assume(invalidByte < 0x30 || invalidByte > 0x39);
        bytes memory input = bytes(value.toString());
        position = bound(position, 0, input.length - 1);
        input[position] = bytes1(invalidByte);

        (bytes4 errorSelector, uint256 result) = LibParseDecimal.unsafeDecimalStringToInt(
            Pointer.unwrap(input.dataPointer()), Pointer.unwrap(input.endDataPointer())
        );
        assertEq(errorSelector, ParseInvalidDecimalChar.selector);
        assertEq(result, 0);
    }

    /// Test that a byte outside `0`-`9` at the 78th-from-last position yields
    /// `ParseInvalidDecimalChar`, not `ParseDecimalOverflow`, including the
    /// boundary bytes immediately adjacent to the digit range.
    function testUnsafeDecimalStrToIntInvalidCharAt78th() external pure {
        string memory zeros = new string(77);
        for (uint256 i = 0; i < 77; i++) {
            bytes(zeros)[i] = "0";
        }
        checkUnsafeStrToIntInvalid(string(abi.encodePacked("a", zeros)));
        // 0x2F, one below the `0` byte.
        checkUnsafeStrToIntInvalid(string(abi.encodePacked("/", zeros)));
        // 0x3A, one above the `9` byte.
        checkUnsafeStrToIntInvalid(string(abi.encodePacked(":", zeros)));
    }

    /// Test that a byte outside `0`-`9` beyond the 78th-from-last position
    /// yields `ParseInvalidDecimalChar`, not `ParseDecimalOverflow`, including
    /// the boundary bytes immediately adjacent to the digit range.
    function testUnsafeDecimalStrToIntInvalidCharBeyond78() external pure {
        string memory zeros = new string(77);
        for (uint256 i = 0; i < 77; i++) {
            bytes(zeros)[i] = "0";
        }
        checkUnsafeStrToIntInvalid(string(abi.encodePacked("a1", zeros)));
        // 0x2F, one below the `0` byte.
        checkUnsafeStrToIntInvalid(string(abi.encodePacked("/1", zeros)));
        // 0x3A, one above the `9` byte.
        checkUnsafeStrToIntInvalid(string(abi.encodePacked(":1", zeros)));
    }

    /// Test that when the region contains both an invalid byte and a digit
    /// that would overflow a uint256, `ParseInvalidDecimalChar` wins
    /// regardless of their relative positions.
    function testUnsafeDecimalStrToIntInvalidCharWinsOverOverflow() external pure {
        string memory zeros76 = new string(76);
        for (uint256 i = 0; i < 76; i++) {
            bytes(zeros76)[i] = "0";
        }
        string memory zeros77 = new string(77);
        for (uint256 i = 0; i < 77; i++) {
            bytes(zeros77)[i] = "0";
        }
        // `5` at the 78th-from-last position would overflow; `a` sits inside
        // the last-77-character window.
        checkUnsafeStrToIntInvalid(string(abi.encodePacked("5a", zeros76)));
        // `5` at the 78th-from-last position would overflow; `a` sits beyond
        // the 78th.
        checkUnsafeStrToIntInvalid(string(abi.encodePacked("a5", zeros77)));
    }

    function checkUnsafeStrToIntAgainstReference(bytes memory data) internal pure {
        (bytes4 slowSelector, uint256 slowValue) = LibParseDecimalSlow.decimalStringToIntSlow(data);
        (bytes4 errorSelector, uint256 result) = LibParseDecimal.unsafeDecimalStringToInt(
            Pointer.unwrap(data.dataPointer()), Pointer.unwrap(data.endDataPointer())
        );
        assertEq(errorSelector, slowSelector);
        assertEq(result, slowValue);
    }

    /// Test that the conversion agrees with the naive reference implementation
    /// on both the selector and the value for arbitrary bytes.
    function testUnsafeDecimalStrToIntReference(bytes memory data) external pure {
        checkUnsafeStrToIntAgainstReference(data);
    }

    /// Test that the conversion agrees with the naive reference implementation
    /// on both the selector and the value for digit-dense strings up to 100
    /// characters, crossing the 77-character accumulation window, with one
    /// arbitrary byte overwriting a digit at any position (or not at all when
    /// the overwrite position lands past the end).
    function testUnsafeDecimalStrToIntReferenceLong(
        uint256 seed,
        uint256 length,
        uint256 overwritePosition,
        uint8 overwriteByte
    ) external pure {
        length = bound(length, 1, 100);
        bytes memory data = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            // forge-lint: disable-next-line(unsafe-typecast)
            data[i] = bytes1(uint8(0x30 + uint256(keccak256(abi.encodePacked(seed, i))) % 10));
        }
        overwritePosition = bound(overwritePosition, 0, length);
        if (overwritePosition < length) {
            data[overwritePosition] = bytes1(overwriteByte);
        }
        checkUnsafeStrToIntAgainstReference(data);
    }
}
