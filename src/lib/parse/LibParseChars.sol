// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity ^0.8.25;

library LibParseChars {
    /// Skip an unlimited number of chars until we find one that is not in the
    /// mask.
    function skipMask(uint256 cursor, uint256 end, uint256 mask) internal pure returns (uint256) {
        assembly ("memory-safe") {
            //slither-disable-next-line incorrect-shift
            for {} and(lt(cursor, end), gt(and(shl(byte(0, mload(cursor)), 1), mask), 0)) { cursor := add(cursor, 1) } {}
        }
        return cursor;
    }

    /// Checks if the cursor points at a char of the given mask, and is in range
    /// of end.
    function isMask(uint256 cursor, uint256 end, uint256 mask) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            //slither-disable-next-line incorrect-shift
            result := and(lt(cursor, end), iszero(iszero(and(shl(byte(0, mload(cursor)), 1), mask))))
        }
    }
}
