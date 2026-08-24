// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {LibParseChar} from "src/lib/parse/LibParseChar.sol";
import {Pointer} from "rain-solmem-0.1.26/src/lib/LibPointer.sol";
import {LibBytes} from "rain-solmem-0.1.26/src/lib/LibBytes.sol";
import {LibParseCharSlow} from "test/lib/parse/LibParseCharSlow.sol";

/// @title LibParseCharIsMaskTest
/// @notice Tests that the isMask function works correctly.
contract LibParseCharIsMaskTest is Test {
    using LibBytes for bytes;

    /// Test that cursor at or past end is always false for isMask.
    function testIsMaskPastEnd(uint256 cursor, uint256 end, uint256 mask) external pure {
        cursor = bound(cursor, end, type(uint256).max);
        assertEq(LibParseChar.isMask(cursor, end, mask), 0);
    }

    /// Test that a cursor far past the end returns 0 rather than paying for
    /// memory expansion out to the cursor. A full mask would report a hit for
    /// any char, so a zero result can only come from the bounds check. The
    /// fuzz args are bound to fixed values so the cursor and end are opaque
    /// at compile time and the load cannot be folded away by the optimizer.
    function testIsMaskFarPastEnd(uint256 cursor, uint256 end) external pure {
        end = bound(end, 0, 0);
        cursor = bound(cursor, 1 << 32, 1 << 32);
        assertEq(LibParseChar.isMask(cursor, end, type(uint256).max), 0);
        cursor = bound(cursor, type(uint256).max, type(uint256).max);
        assertEq(LibParseChar.isMask(cursor, end, type(uint256).max), 0);
        assertEq(LibParseChar.isMask(cursor, cursor, type(uint256).max), 0);
    }

    /// Test that isMask matches a reference implementation.
    function testIsMaskReference(string memory s, uint256 index, uint256 mask) external pure {
        vm.assume(bytes(s).length > 0);
        index = bound(index, 0, bytes(s).length - 1);

        uint256 cursor = Pointer.unwrap(bytes(s).dataPointer()) + index;
        uint256 end = Pointer.unwrap(bytes(s).endDataPointer());

        assertEq(LibParseChar.isMask(cursor, end, mask), LibParseCharSlow.isMaskSlow(cursor, end, mask));
    }
}
