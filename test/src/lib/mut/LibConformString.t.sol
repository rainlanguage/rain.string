// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibConformString} from "src/lib/mut/LibConformString.sol";
import {LibParseChar} from "src/lib/parse/LibParseChar.sol";

contract LibConformStringTest is Test {
    function testConformStringFuzz(string memory s, uint256 mask) external pure {
        vm.assume(mask != 0);

        LibConformString.conformStringToMask(s, mask, 0x100);

        uint256 cursor;
        uint256 end;
        assembly ("memory-safe") {
            cursor := add(s, 0x20)
            end := add(cursor, mload(s))
        }

        cursor = LibParseChar.skipMask(cursor, end, mask);

        assertEq(cursor, end);
    }
}
