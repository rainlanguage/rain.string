// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {CMASK_NEGATIVE_SIGN} from "./LibParseCMask.sol";
import {LibParseChar} from "./LibParseChar.sol";
import {
    ParseDecimalOverflow,
    ParseEmptyDecimalString,
    ParseInvalidDecimalChar,
    ZeroStringStartPointer
} from "../../error/ErrParse.sol";

library LibParseDecimal {
    /// @notice Convert a decimal ASCII string in a memory region to a `uint256`
    /// integer.
    /// DOES check that every byte in the region is a decimal character `0`-`9`:
    /// any other byte anywhere in the region yields `ParseInvalidDecimalChar`.
    /// When the region contains both an invalid byte and digits that would
    /// overflow, `ParseInvalidDecimalChar` wins.
    /// DOES check for unsigned integer overflow.
    /// `unsafe` refers to the pointers: `start` and `end` are read as raw
    /// memory addresses with no bounds or ownership checks, so the caller is
    /// responsible for them delimiting a readable region.
    /// @param start The start of the memory region containing the decimal ASCII
    /// string.
    /// @param end The end of the memory region containing the decimal ASCII
    /// string.
    /// @return The error selector if the conversion failed, `0` otherwise.
    /// The selector is returned bare: `ParseEmptyDecimalString`,
    /// `ParseDecimalOverflow` and `ParseInvalidDecimalChar` declare a
    /// `uint256 position` parameter, but this library does not know the
    /// caller's position, so a caller that reverts with the selector appends
    /// its own position.
    /// @return The unsigned integer representation of the ASCII string.
    /// ALWAYS check the error selector before using the value.
    function unsafeDecimalStringToInt(uint256 start, uint256 end) internal pure returns (bytes4, uint256) {
        unchecked {
            if (start >= end) {
                return (ParseEmptyDecimalString.selector, 0);
            }

            // This edge case is not supported because it is rarely useful and
            // would add gas overhead on every loop iteration below.
            if (start == 0) {
                revert ZeroStringStartPointer();
            }

            // The ASCII byte can be translated to a numeric digit by subtracting
            // the digit offset.
            // forge-lint: disable-next-line(unsafe-typecast)
            uint256 digitOffset = uint256(uint8(bytes1("0")));
            uint256 exponent = 0;
            uint256 cursor;
            cursor = end - 1;
            uint256 value = 0;
            // Nonzero when any byte seen so far maps outside the digit range
            // 0-9. Accumulated branchlessly beside the digit math so the
            // loops stay jump free; checked once after the loops.
            uint256 nonDigit = 0;

            // Anything under 10^77 is safe to raise to its power of 10 without
            // overflowing a uint256.
            while (cursor >= start && exponent < 77) {
                assembly ("memory-safe") {
                    let digit := sub(byte(0, mload(cursor)), digitOffset)
                    nonDigit := or(nonDigit, gt(digit, 9))
                    value := add(value, mul(digit, exp(10, exponent)))
                }
                exponent++;
                cursor--;
            }

            // If we didn't consume the entire literal, then we have
            // to check if the remaining digit is safe to multiply
            // by 10 without overflowing a uint256.
            if (cursor >= start) {
                uint256 digit;
                assembly ("memory-safe") {
                    digit := sub(byte(0, mload(cursor)), digitOffset)
                    nonDigit := or(nonDigit, gt(digit, 9))
                }
                cursor--;

                // Everything left of the 78th-from-last character must be a
                // leading zero for the value to fit a uint256. Nonzero digits
                // accumulate into a flag instead of returning early so that
                // an invalid byte anywhere in the region still classifies as
                // invalid rather than as overflow.
                uint256 nonZeroLeading = 0;
                while (cursor >= start) {
                    assembly ("memory-safe") {
                        let leadingDigit := sub(byte(0, mload(cursor)), digitOffset)
                        nonDigit := or(nonDigit, gt(leadingDigit, 9))
                        nonZeroLeading := or(nonZeroLeading, iszero(iszero(leadingDigit)))
                    }
                    cursor--;
                }

                if (nonDigit != 0) {
                    return (ParseInvalidDecimalChar.selector, 0);
                }

                // A digit greater than 1 multiplied by 10^77 overflows a
                // uint256, as does any nonzero digit further left.
                if (digit > 1 || nonZeroLeading != 0) {
                    return (ParseDecimalOverflow.selector, 0);
                }
                uint256 scaled = digit * (10 ** exponent);
                if (value + scaled < value) {
                    return (ParseDecimalOverflow.selector, 0);
                }
                value += scaled;
                return (bytes4(0), value);
            }

            if (nonDigit != 0) {
                return (ParseInvalidDecimalChar.selector, 0);
            }

            return (bytes4(0), value);
        }
    }

    /// @notice Convert a decimal ASCII string in a memory region to a signed
    /// integer.
    /// An optional single leading negative sign is consumed; every byte after
    /// it is checked to be a decimal character `0`-`9` by the unsigned
    /// conversion, so any other byte anywhere in the region yields
    /// `ParseInvalidDecimalChar`.
    /// DOES check for signed integer overflow.
    /// `unsafe` refers to the pointers: `start` and `end` are read as raw
    /// memory addresses with no bounds or ownership checks, so the caller is
    /// responsible for them delimiting a readable region.
    /// @param start The start of the memory region containing the decimal ASCII
    /// string.
    /// @param end The end of the memory region containing the decimal ASCII
    /// string.
    /// @return The error selector if the conversion failed, `0` otherwise.
    /// The selector is returned bare: `ParseEmptyDecimalString`,
    /// `ParseDecimalOverflow` and `ParseInvalidDecimalChar` declare a
    /// `uint256 position` parameter, but this library does not know the
    /// caller's position, so a caller that reverts with the selector appends
    /// its own position.
    /// @return The signed integer representation of the ASCII string.
    /// ALWAYS check the error selector before using the value.
    function unsafeDecimalStringToSignedInt(uint256 start, uint256 end) internal pure returns (bytes4, int256) {
        unchecked {
            // Empty regions are reported before the zero start pointer check,
            // matching `unsafeDecimalStringToInt`.
            if (start >= end) {
                return (ParseEmptyDecimalString.selector, 0);
            }

            // A zero start pointer is rejected before the negative sign check
            // reads the byte at `start`, so the rejection cannot be bypassed
            // by scratch memory happening to hold a negative sign character.
            if (start == 0) {
                revert ZeroStringStartPointer();
            }

            uint256 cursor = start;
            uint256 isNeg = LibParseChar.isMask(cursor, end, CMASK_NEGATIVE_SIGN);
            cursor += isNeg;

            (bytes4 errorSelector, uint256 value) = LibParseDecimal.unsafeDecimalStringToInt(cursor, end);
            // Handle failure.
            if (errorSelector != bytes4(0)) {
                return (errorSelector, 0);
            }

            // Handle positive value.
            if (isNeg == 0) {
                if (value > uint256(type(int256).max)) {
                    return (ParseDecimalOverflow.selector, 0);
                }
                // typecast is safe because we know that value is less than or
                // equal to type(int256).max.
                // forge-lint: disable-next-line(unsafe-typecast)
                return (bytes4(0), int256(value));
            }

            // Fallback to negative value.
            if (value > uint256(type(int256).max) + 1) {
                return (ParseDecimalOverflow.selector, 0);
            }
            // typecast is safe because we know that value is less than or equal
            // to type(int256).max + 1. When `value == type(int256).max + 1` the
            // cast wraps to type(int256).min, and negating type(int256).min is
            // itself, which is the correct result.
            // forge-lint: disable-next-line(unsafe-typecast)
            return (bytes4(0), -int256(value));
        }
    }
}
