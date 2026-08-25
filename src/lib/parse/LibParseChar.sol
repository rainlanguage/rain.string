// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title LibParseChar
/// @notice Branchless single-character membership tests against uint256
/// character masks over raw memory cursors.
library LibParseChar {
    /// Skip an unlimited number of chars until we find one that is not in the
    /// mask. If the cursor is at or past the end, the result is the cursor.
    /// This function is expected to be used in very hot gas sensitive loops
    /// so the bounds check is branchless: instead of jumping over the char
    /// load when the cursor is out of range, the load address is zeroed so
    /// only scratch space is ever read. The function IS guaranteed never to
    /// move the cursor past the end if it was not already there.
    /// Otherwise, the result points to the first char that is not in the mask.
    /// @param cursor The current position in the data.
    /// @param end The end of the data.
    /// @param mask The mask to check against.
    function skipMask(uint256 cursor, uint256 end, uint256 mask) internal pure returns (uint256) {
        assembly ("memory-safe") {
            let inRange := lt(cursor, end)
            //slither-disable-next-line incorrect-shift
            for {} and(inRange, gt(and(shl(byte(0, mload(mul(cursor, inRange))), 1), mask), 0)) {
                cursor := add(cursor, 1)
                inRange := lt(cursor, end)
            } {}
        }
        return cursor;
    }

    /// Checks if the cursor points at a char of the given mask, and is in range
    /// of end. If the cursor is at or past the end, the result is `0`. The
    /// bounds check is branchless: instead of jumping over the char load when
    /// the cursor is out of range, the load address is zeroed so only scratch
    /// space is ever read.
    /// @param cursor The current position in the data.
    /// @param end The end of the data.
    /// @param mask The mask to check against.
    /// @return result `1` if the cursor points at a char of the given mask and
    /// is in range of end, `0` otherwise.
    function isMask(uint256 cursor, uint256 end, uint256 mask) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            let inRange := lt(cursor, end)
            //slither-disable-next-line incorrect-shift
            result := and(inRange, iszero(iszero(and(shl(byte(0, mload(mul(cursor, inRange))), 1), mask))))
        }
    }
}
