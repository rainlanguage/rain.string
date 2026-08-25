// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.2/src/Test.sol";

import {LibParseChar} from "../../../../src/lib/parse/LibParseChar.sol";
import {Pointer} from "rain-solmem-0.1.26/src/lib/LibPointer.sol";
import {LibBytes} from "rain-solmem-0.1.26/src/lib/LibBytes.sol";
import {LibParseCharSlow} from "../../../lib/parse/LibParseCharSlow.sol";

/// @title LibParseCharSkipMaskTest
/// @notice Tests that the skipMask function works correctly.
contract LibParseCharSkipMaskTest is Test {
    using LibBytes for bytes;

    /// Test that cursor at or past end is always the end for skipMask.
    function testSkipMaskPastEnd(uint256 cursor, uint256 end, uint256 mask) external pure {
        cursor = bound(cursor, end, type(uint256).max);
        assertEq(LibParseChar.skipMask(cursor, end, mask), cursor);
    }

    /// Test that a cursor far past the end is returned unchanged rather than
    /// paying for memory expansion out to the cursor. A full mask would skip
    /// any char, so an unchanged cursor can only come from the bounds check.
    /// The fuzz args are bound to fixed values so the cursor and end are
    /// opaque at compile time and the load cannot be folded away by the
    /// optimizer.
    function testSkipMaskFarPastEnd(uint256 cursor, uint256 end) external pure {
        end = bound(end, 0, 0);
        cursor = bound(cursor, 1 << 32, 1 << 32);
        assertEq(LibParseChar.skipMask(cursor, end, type(uint256).max), 1 << 32);
        cursor = bound(cursor, type(uint256).max, type(uint256).max);
        assertEq(LibParseChar.skipMask(cursor, end, type(uint256).max), type(uint256).max);
        assertEq(LibParseChar.skipMask(cursor, cursor, type(uint256).max), type(uint256).max);
    }

    /// Test that skipMask stops exactly at the end even when the chars just
    /// past the end are also in the mask.
    function testSkipMaskStopsAtEnd() external pure {
        bytes memory s = new bytes(64);
        for (uint256 i = 0; i < 64; i++) {
            s[i] = "a";
        }
        uint256 cursor = Pointer.unwrap(s.dataPointer());
        uint256 end = cursor + 32;
        // forge-lint: disable-next-line(incorrect-shift,unsafe-typecast)
        assertEq(LibParseChar.skipMask(cursor, end, 1 << uint256(uint8(bytes1("a")))), end);
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
