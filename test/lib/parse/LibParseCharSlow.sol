// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title LibParseCharSlow
/// @notice Naive reference implementations of the `LibParseChar` library,
/// written with explicit bounds branches rather than the production
/// branchless assembly, for equivalence testing.
library LibParseCharSlow {
    /// Reference for `LibParseChar.skipMask`, stepping the cursor one char at
    /// a time with an explicit bounds branch per step.
    /// @param cursor The current position in the data.
    /// @param end The end of the data.
    /// @param mask The mask to check against.
    /// @return The first position in `[cursor, end)` pointing at a char not in
    /// the mask, `end` if every char in that range is in the mask, or `cursor`
    /// unchanged if it is already at or past `end`.
    function skipMaskSlow(uint256 cursor, uint256 end, uint256 mask) internal pure returns (uint256) {
        while (cursor < end) {
            uint256 wordAtCursor;
            assembly ("memory-safe") {
                wordAtCursor := mload(cursor)
            }
            // forge-lint: disable-next-line(incorrect-shift)
            if ((1 << uint256(wordAtCursor >> 0xF8)) & mask == 0) {
                break;
            }
            cursor += 1;
        }
        return cursor;
    }

    /// Reference for `LibParseChar.isMask`, with an explicit bounds branch
    /// instead of the production branchless assembly.
    /// @param cursor The current position in the data.
    /// @param end The end of the data.
    /// @param mask The mask to check against.
    /// @return `1` if the cursor is in range of `end` and points at a char in
    /// the mask, `0` otherwise.
    function isMaskSlow(uint256 cursor, uint256 end, uint256 mask) internal pure returns (uint256) {
        if (cursor < end) {
            uint256 wordAtCursor;
            assembly ("memory-safe") {
                wordAtCursor := mload(cursor)
            }
            // forge-lint: disable-next-line(incorrect-shift)
            return (1 << uint256(wordAtCursor >> 0xF8)) & mask > 0 ? 1 : 0;
        } else {
            return 0;
        }
    }
}
