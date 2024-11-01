// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity ^0.8.25;

library LibParseChar {
    /// Skip an unlimited number of chars until we find one that is not in the
    /// mask. If the cursor is at or past the end, the result is the cursor.
    /// This function DOES NOT check if the cursor is in range of the end as it
    /// is expected to be used in very hot gas sensitive loops so we want to
    /// avoid jumps. The function IS guaranteed never to move the cursor past
    /// the end if it was not already there.
    /// Otherwise, the result points to the first char that is not in the mask.
    /// @param cursor The current position in the data.
    /// @param end The end of the data.
    /// @param mask The mask to check against.
    function skipMask(uint256 cursor, uint256 end, uint256 mask) internal pure returns (uint256) {
        assembly ("memory-safe") {
            //slither-disable-next-line incorrect-shift
            for {} and(lt(cursor, end), gt(and(shl(byte(0, mload(cursor)), 1), mask), 0)) { cursor := add(cursor, 1) } {}
        }
        return cursor;
    }

    /// Checks if the cursor points at a char of the given mask, and is in range
    /// of end. If the cursor is at or past the end, the result is `0`.
    /// @param cursor The current position in the data.
    /// @param end The end of the data.
    /// @param mask The mask to check against.
    /// @return `1` if the cursor points at a char of the given mask and is in
    /// range of end, `0` otherwise.
    function isMask(uint256 cursor, uint256 end, uint256 mask) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            //slither-disable-next-line incorrect-shift
            result := and(lt(cursor, end), iszero(iszero(and(shl(byte(0, mload(cursor)), 1), mask))))
        }
    }
}
