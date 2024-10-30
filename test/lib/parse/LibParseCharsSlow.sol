// SPDX-License-Identifier: CAL
pragma solidity ^0.8.25;

library LibParseCharsSlow {
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
