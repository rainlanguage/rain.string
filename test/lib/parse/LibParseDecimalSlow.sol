// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {ParseDecimalOverflow, ParseEmptyDecimalString, ParseInvalidDecimalChar} from "../../../src/error/ErrParse.sol";

/// @title LibParseDecimalSlow
/// @notice Naive reference implementation of the decimal parsing contract,
/// written directly from the spec rather than from the production code: an
/// empty region is an empty decimal string, any byte outside `0`-`9` anywhere
/// in the region is an invalid decimal character (taking precedence over
/// overflow), and otherwise digits accumulate left to right with an explicit
/// overflow check at each step.
library LibParseDecimalSlow {
    /// Reference for `LibParseDecimal.unsafeDecimalStringToInt` over a
    /// `bytes` array instead of raw pointers.
    /// @param data The ASCII string to convert.
    /// @return The error selector if the conversion failed, `0` otherwise.
    /// @return The unsigned integer representation of the ASCII string.
    function decimalStringToIntSlow(bytes memory data) internal pure returns (bytes4, uint256) {
        if (data.length == 0) {
            return (ParseEmptyDecimalString.selector, 0);
        }

        for (uint256 i = 0; i < data.length; i++) {
            // forge-lint: disable-next-line(unsafe-typecast)
            uint256 char = uint256(uint8(data[i]));
            if (char < 0x30 || char > 0x39) {
                return (ParseInvalidDecimalChar.selector, 0);
            }
        }

        uint256 value = 0;
        for (uint256 i = 0; i < data.length; i++) {
            // forge-lint: disable-next-line(unsafe-typecast)
            uint256 digit = uint256(uint8(data[i])) - 0x30;
            // `value * 10 + digit` fits a uint256 iff
            // `value <= (type(uint256).max - digit) / 10`.
            if (value > (type(uint256).max - digit) / 10) {
                return (ParseDecimalOverflow.selector, 0);
            }
            value = value * 10 + digit;
        }
        return (bytes4(0), value);
    }
}
