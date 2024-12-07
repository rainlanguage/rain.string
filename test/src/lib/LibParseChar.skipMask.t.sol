// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibParseChar} from "src/lib/parse/LibParseChar.sol";
import {LibPointer, Pointer} from "rain.solmem/lib/LibPointer.sol";
import {LibBytes} from "rain.solmem/lib/LibBytes.sol";
import {LibParseCharSlow} from "test/lib/parse/LibParseCharSlow.sol";

/// @title LibParseCharSkipMaskTest
/// @notice Tests that the isMask function works correctly.
contract LibParseCharSkipMaskTest is Test {
    using LibBytes for bytes;

    /// Test that cursor at or past end is always the end for skipMask.
    function testSkipMaskPastEnd(uint256 cursor, uint256 end, uint256 mask) external pure {
        // Limit to 16-bit values to avoid OOM reads.
        end = bound(end, 0, type(uint16).max);
        cursor = bound(cursor, end, type(uint16).max);
        assertEq(LibParseChar.skipMask(cursor, end, mask), cursor);
    }

    /// Test that skipMask matches a reference implementation.
    function testSkipMaskReference(string memory s, uint256 index, uint256 mask) external pure {
        vm.assume(bytes(s).length > 0);
        index = bound(index, 0, bytes(s).length - 1);

        uint256 cursor = Pointer.unwrap(bytes(s).dataPointer()) + index;
        uint256 end = Pointer.unwrap(bytes(s).endDataPointer());

        assertEq(LibParseChar.skipMask(cursor, end, mask), LibParseCharSlow.skipMaskSlow(cursor, end, mask));
    }
}
