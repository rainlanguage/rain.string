// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity ^0.8.25;

library LibParseDecimal {
    /// @notice Convert a decimal ASCII string in a memory region to an
    /// 18 decimal fixed point `uint256`.
    /// DOES NOT check that the string contains valid decimal characters. You can
    /// use `LibParseChar.skipMask` to easily bound some valid decimal characters.
    /// DOES check for overflow in the fixed point representation.
    /// @param start The start of the memory region containing the decimal ASCII
    /// string.
    /// @param end The end of the memory region containing the decimal ASCII
    /// string.
    /// @return Whether the conversion was successful. If `0`, this is
    /// due to an overflow, if `1` the conversion was successful.
    /// @return The fixed point decimal representation of the ASCII string.
    /// ALWAYS check `success` before using `value`, otherwise you cannot
    /// distinguish between `0` and a failed conversion.
    function unsafeDecimalStringToInt(uint256 start, uint256 end) internal pure returns (uint256, uint256) {
        unchecked {
            // The ASCII byte can be translated to a numeric digit by subtracting
            // the digit offset.
            uint256 digitOffset = uint256(uint8(bytes1("0")));
            uint256 exponent = 0;
            uint256 cursor;
            cursor = end - 1;
            uint256 value = 0;

            // Anything under 10^77 is safe to raise to its power of 10 without
            // overflowing a uint256.
            while (cursor >= start && exponent < 77) {
                // We don't need to check the bounds of the byte because
                // we know it is a decimal literal as long as the bounds
                // are correct (calculated in `boundLiteral`).
                assembly ("memory-safe") {
                    value := add(value, mul(sub(byte(0, mload(cursor)), digitOffset), exp(10, exponent)))
                }
                exponent++;
                cursor--;
            }

            // If we didn't consume the entire literal, then we have
            // to check if the remaining digit is safe to multiply
            // by 10 without overflowing a uint256.
            if (cursor >= start) {
                {
                    uint256 digit;
                    assembly ("memory-safe") {
                        digit := sub(byte(0, mload(cursor)), digitOffset)
                    }
                    // If the digit is greater than 1, then we know that
                    // multiplying it by 10^77 will overflow a uint256.
                    if (digit > 1) {
                        return (0, 0);
                    } else {
                        uint256 scaled = digit * (10 ** exponent);
                        if (value + scaled < value) {
                            return (0, 0);
                        }
                        value += scaled;
                    }
                    cursor--;
                }

                {
                    // If we didn't consume the entire literal, then only
                    // leading zeros are allowed.
                    while (cursor >= start) {
                        //slither-disable-next-line similar-names
                        uint256 decimalCharByte;
                        assembly ("memory-safe") {
                            decimalCharByte := byte(0, mload(cursor))
                        }
                        if (decimalCharByte != uint256(uint8(bytes1("0")))) {
                            return (0, 0);
                        }
                        cursor--;
                    }
                }
            }

            return (1, value);
        }
    }
}
