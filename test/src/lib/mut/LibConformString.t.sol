// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {stdError} from "forge-std-1.16.1/src/StdError.sol";

import {LibConformString} from "src/lib/mut/LibConformString.sol";
import {LibParseChar} from "src/lib/parse/LibParseChar.sol";
import {CMASK_STRING_LITERAL_TAIL, CMASK_HEX, CMASK_WHITESPACE} from "src/lib/parse/LibParseCMask.sol";
import {EmptyStringMask} from "src/error/ErrConform.sol";

contract LibConformStringTest is Test {
    function externalConformStringToMask(string memory str, uint256 mask, uint256 max) external pure {
        LibConformString.conformStringToMask(str, mask, max);
    }

    function externalCharFromMask(uint256 seed, uint256 mask) external pure returns (bytes1) {
        return LibConformString.charFromMask(seed, mask);
    }

    function externalCorruptSingleChar(string memory str, uint256 index) external pure returns (string memory) {
        LibConformString.corruptSingleChar(str, index);
        return str;
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

    /// max == 1 is valid as long as the mask includes the null character, and
    /// every character not already in the mask is rewritten to it.
    function testConformStringMaxOne() external pure {
        string memory s = "abc";
        LibConformString.conformStringToMask(s, 1, 1);
        assertEq(s, "\x00\x00\x00");
    }

    /// Characters are always generated strictly below max, so a mask bit at or
    /// above max is only reachable for characters that already have it. Here
    /// 0x20 is the only mask bit below max, so every rewritten character must
    /// land on it.
    function testConformStringGeneratedCharsBelowMax() external pure {
        uint256 mask = (1 << 0x20) | (1 << 0xC3);
        // A fresh string is all null bytes, none of which are in the mask.
        string memory s = new string(64);
        LibConformString.conformStringToMask(s, mask, 0x30);
        for (uint256 i = 0; i < bytes(s).length; i++) {
            assertEq(uint8(bytes(s)[i]), 0x20);
        }
    }

    /// Conforming is deterministic: the same input string and mask always
    /// produce the same output, regardless of surrounding memory state.
    function testConformStringDeterminism(string memory a, uint256 mask) external pure {
        vm.assume(mask != 0);
        string memory orig = string(bytes.concat(bytes(a)));
        LibConformString.conformStringToMask(a, mask, 0x100);
        string memory b = string(bytes.concat(bytes(orig)));
        LibConformString.conformStringToMask(b, mask, 0x100);
        assertEq(a, b);
    }

    /// The 2-arg overload restricts generated characters to the ASCII range.
    /// 0x41 is the only mask bit below 0x80, so every rewritten character must
    /// land on it even though the mask also has a bit above the ASCII range.
    function testConformStringTwoArgOverloadAsciiRange() external pure {
        uint256 mask = (1 << 0x41) | (1 << 0xC3);
        string memory s = new string(64);
        LibConformString.conformStringToMask(s, mask);
        for (uint256 i = 0; i < bytes(s).length; i++) {
            assertEq(uint8(bytes(s)[i]), 0x41);
        }
    }

    /// conformStringToAscii rewrites every non-ASCII byte to an ASCII one and
    /// leaves ASCII bytes untouched.
    function testConformStringToAscii() external pure {
        bytes memory b = hex"6180c3ff0022";
        string memory s = string(b);
        LibConformString.conformStringToAscii(s);
        for (uint256 i = 0; i < bytes(s).length; i++) {
            assertTrue(uint8(bytes(s)[i]) < 0x80);
        }
        // ASCII bytes are already in the mask so are byte-identical.
        assertEq(uint8(bytes(s)[0]), 0x61);
        assertEq(uint8(bytes(s)[4]), 0x00);
        assertEq(uint8(bytes(s)[5]), 0x22);
    }

    /// Every byte of the result is ASCII for any input.
    function testConformStringToAsciiFuzz(bytes memory b) external pure {
        string memory s = string(b);
        LibConformString.conformStringToAscii(s);
        for (uint256 i = 0; i < bytes(s).length; i++) {
            assertTrue(uint8(bytes(s)[i]) < 0x80);
        }
    }

    /// conformStringToHexDigits rewrites every non-hex byte to a hex digit and
    /// leaves hex digits untouched.
    function testConformStringToHexDigits() external pure {
        bytes memory b = hex"306641467a210040ff";
        string memory s = string(b);
        LibConformString.conformStringToHexDigits(s);
        // Hex digits are already in the mask so are byte-identical.
        assertEq(uint8(bytes(s)[0]), uint8(bytes1("0")));
        assertEq(uint8(bytes(s)[1]), uint8(bytes1("f")));
        assertEq(uint8(bytes(s)[2]), uint8(bytes1("A")));
        assertEq(uint8(bytes(s)[3]), uint8(bytes1("F")));
        for (uint256 i = 0; i < bytes(s).length; i++) {
            uint256 char = uint256(uint8(bytes(s)[i]));
            // forge-lint: disable-next-line(incorrect-shift)
            assertTrue((1 << char) & uint256(CMASK_HEX) != 0);
        }
    }

    /// conformValidPrintableStringContent rewrites every byte outside the
    /// string literal tail mask (including double quotes) to a byte inside it,
    /// and leaves bytes inside it untouched.
    function testConformValidPrintableStringContent() external pure {
        bytes memory b = hex"2222226141";
        string memory s = string(b);
        LibConformString.conformValidPrintableStringContent(s);
        for (uint256 i = 0; i < bytes(s).length; i++) {
            uint256 char = uint256(uint8(bytes(s)[i]));
            // forge-lint: disable-next-line(incorrect-shift)
            assertTrue((1 << char) & uint256(CMASK_STRING_LITERAL_TAIL) != 0);
        }
        // Valid literal tail characters are already in the mask so are
        // byte-identical.
        assertEq(uint8(bytes(s)[3]), uint8(bytes1("a")));
        assertEq(uint8(bytes(s)[4]), uint8(bytes1("A")));
    }

    /// conformStringToWhitespace rewrites every non-whitespace byte to one of
    /// \t \n \r space and leaves whitespace bytes untouched.
    function testConformStringToWhitespace() external pure {
        bytes memory b = hex"21212161090a0d20";
        string memory s = string(b);
        LibConformString.conformStringToWhitespace(s);
        for (uint256 i = 0; i < bytes(s).length; i++) {
            uint256 char = uint256(uint8(bytes(s)[i]));
            // forge-lint: disable-next-line(incorrect-shift)
            assertTrue((1 << char) & uint256(CMASK_WHITESPACE) != 0);
        }
        // Whitespace characters are already in the mask so are byte-identical.
        assertEq(uint8(bytes(s)[4]), 0x09);
        assertEq(uint8(bytes(s)[5]), 0x0A);
        assertEq(uint8(bytes(s)[6]), 0x0D);
        assertEq(uint8(bytes(s)[7]), 0x20);
    }

    /// corruptSingleChar replaces exactly the byte at the given index with a
    /// byte that is not valid string literal tail content and is not a double
    /// quote. Every other byte and the length are untouched.
    function testCorruptSingleChar() external pure {
        string memory s = "abcd";
        LibConformString.corruptSingleChar(s, 2);
        assertEq(bytes(s).length, 4);
        assertEq(uint8(bytes(s)[0]), uint8(bytes1("a")));
        assertEq(uint8(bytes(s)[1]), uint8(bytes1("b")));
        assertEq(uint8(bytes(s)[3]), uint8(bytes1("d")));
        uint256 char = uint256(uint8(bytes(s)[2]));
        // forge-lint: disable-next-line(incorrect-shift)
        assertTrue((1 << char) & uint256(CMASK_STRING_LITERAL_TAIL) == 0);
        assertTrue(char != uint256(uint8(bytes1("\""))));
    }

    /// A double quote is corrupted to something else even though it is already
    /// outside the string literal tail mask.
    function testCorruptSingleCharQuote() external pure {
        string memory s = "\"\"";
        LibConformString.corruptSingleChar(s, 0);
        uint256 char = uint256(uint8(bytes(s)[0]));
        assertTrue(char != uint256(uint8(bytes1("\""))));
        // forge-lint: disable-next-line(incorrect-shift)
        assertTrue((1 << char) & uint256(CMASK_STRING_LITERAL_TAIL) == 0);
        // The sibling byte is untouched.
        assertEq(uint8(bytes(s)[1]), uint8(bytes1("\"")));
    }

    /// A byte that is already outside the string literal tail mask (and is not
    /// a double quote) is written back unchanged.
    function testCorruptSingleCharAlreadyInvalid() external pure {
        bytes memory b = hex"001f7f";
        string memory s = string(b);
        LibConformString.corruptSingleChar(s, 0);
        LibConformString.corruptSingleChar(s, 1);
        LibConformString.corruptSingleChar(s, 2);
        assertEq(uint8(bytes(s)[0]), 0x00);
        assertEq(uint8(bytes(s)[1]), 0x1F);
        assertEq(uint8(bytes(s)[2]), 0x7F);
    }

    /// An index at the end of the string is out of bounds and panics.
    function testCorruptSingleCharOutOfBoundsReverts() external {
        vm.expectRevert(stdError.indexOOBError);
        this.externalCorruptSingleChar("abc", 3);
    }

    /// Any index at or beyond the length is out of bounds and panics.
    function testCorruptSingleCharOutOfBoundsRevertsFuzz(string memory s, uint256 index) external {
        index = bound(index, bytes(s).length, type(uint256).max);
        vm.expectRevert(stdError.indexOOBError);
        this.externalCorruptSingleChar(s, index);
    }

    /// The character search starts at 0, so any mask with the null bit set
    /// yields the null character for every seed.
    function testCharFromMaskBitZero(uint256 seed, uint256 mask) external pure {
        mask |= 1;
        assertEq(uint8(LibConformString.charFromMask(seed, mask)), 0);
    }

    /// charFromMask is deterministic in (seed, mask) regardless of surrounding
    /// memory state.
    function testCharFromMaskDeterminism(uint256 seed) external pure {
        bytes1 first = LibConformString.charFromMask(seed, uint256(CMASK_HEX));
        bytes memory pad = new bytes(32);
        assertEq(pad.length, 32);
        bytes1 second = LibConformString.charFromMask(seed, uint256(CMASK_HEX));
        assertEq(uint8(first), uint8(second));
    }
}
