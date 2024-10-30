// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 thedavidmeister
pragma solidity ^0.8.25;

library LibParseCharSlow {
    function isMaskSlow(uint256 cursor, uint256 end, uint256 mask) internal pure returns (uint256) {
        if (cursor < end) {
            uint256 wordAtCursor;
            assembly ("memory-safe") {
                wordAtCursor := mload(cursor)
            }
            return (1 << uint256(wordAtCursor >> 0xF8)) & mask > 0 ? 1 : 0;
        } else {
            return 0;
        }
    }
}
