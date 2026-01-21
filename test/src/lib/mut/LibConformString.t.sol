// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";

import {LibConformString} from "src/lib/mut/LibConformString.sol";
import {LibParseChar} from "src/lib/parse/LibParseChar.sol";
import {EmptyStringMask} from "src/error/ErrConform.sol";

contract LibConformStringTest is Test {
    function externalConformStringToMask(string memory str, uint256 mask, uint256 max) external pure {
        LibConformString.conformStringToMask(str, mask, max);
    }

    function externalCharFromMask(uint256 seed, uint256 mask) external pure returns (bytes1) {
        return LibConformString.charFromMask(seed, mask);
    }

    function testConformStringZeroMaskRevert(string memory s, uint256 max) external {
        vm.expectRevert(abi.encodeWithSelector(EmptyStringMask.selector));
        this.externalConformStringToMask(s, 0, max);
    }

    function testConformStringZeroMaxRevert(string memory s, uint256 mask) external {
        vm.expectRevert(abi.encodeWithSelector(EmptyStringMask.selector));
        this.externalConformStringToMask(s, mask, 0);
    }

    function testConformStringMaxNoPossibleCharsRevert(string memory s, uint256 mask, uint256 max) external {
        vm.assume(max < 0x100);
        // Ensure that there are no possible characters in the mask
        uint256 limitedMask = mask & ((1 << max) - 1);
        vm.assume(limitedMask == 0);
        vm.expectRevert(abi.encodeWithSelector(EmptyStringMask.selector));
        this.externalConformStringToMask(s, mask, max);
    }

    function testConformStringMax256OrHigherNeverReverts(string memory s, uint256 mask, uint256 max) external view {
        max = bound(max, 0x100, type(uint256).max);
        vm.assume(mask != 0);
        // This should never revert, as all characters are possible.
        this.externalConformStringToMask(s, mask, max);
    }

    function testCharFromZeroMaskRevert(uint256 seed) external {
        vm.expectRevert(abi.encodeWithSelector(EmptyStringMask.selector));
        this.externalCharFromMask(seed, 0);
    }

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

    function testCharFromMask(uint256 seed, uint256 mask) external pure {
        vm.assume(mask != 0);

        bytes1 c = LibConformString.charFromMask(seed, mask);

        uint256 char = uint256(uint8(c));
        // forge-lint: disable-next-line(incorrect-shift)
        assertTrue((1 << char) & mask != 0);

        string memory s = new string(1);
        bytes(s)[0] = c;

        string memory sInit = new string(1);
        bytes(sInit)[0] = c;

        LibConformString.conformStringToMask(s, mask, type(uint256).max);
        assertEq(s, sInit);

        uint256 sInitPointer;
        uint256 sPointer;
        assembly ("memory-safe") {
            sInitPointer := sInit
            sPointer := s
        }
        assertTrue(sPointer != sInitPointer);
    }
}
