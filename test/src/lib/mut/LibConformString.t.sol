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
    function externalConformStringToMask(string memory str, uint256 mask) external pure {
        LibConformString.conformStringToMask(str, mask);
    }

    function externalCharFromMask(uint256 seed, uint256 mask) external pure returns (bytes1) {
        return LibConformString.charFromMask(seed, mask);
    }

    function externalCorruptSingleChar(string memory str, uint256 index) external pure returns (string memory) {
        LibConformString.corruptSingleChar(str, index);
        return str;
    }

    /// A zero mask reverts before any character is processed, so even the
    /// empty string reverts.
    function testConformStringZeroMaskRevert() external {
        vm.expectRevert(abi.encodeWithSelector(EmptyStringMask.selector));
        this.externalConformStringToMask("", 0);
        vm.expectRevert(abi.encodeWithSelector(EmptyStringMask.selector));
        this.externalConformStringToMask("abc", 0);
    }

    function testCharFromZeroMaskRevert(uint256 seed) external {
        vm.expectRevert(abi.encodeWithSelector(EmptyStringMask.selector));
        this.externalCharFromMask(seed, 0);
    }

    function testConformStringFuzz(string memory s, uint256 mask) external pure {
        vm.assume(mask != 0);

        LibConformString.conformStringToMask(s, mask);

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

        LibConformString.conformStringToMask(s, mask);
        assertEq(s, sInit);

        uint256 sInitPointer;
        uint256 sPointer;
        assembly ("memory-safe") {
            sInitPointer := sInit
            sPointer := s
        }
        assertTrue(sPointer != sInitPointer);
    }

    /// A mask of just the null character rewrites every character to null.
    function testConformStringNullMaskOnly() external pure {
        string memory s = "abc";
        LibConformString.conformStringToMask(s, 1);
        assertEq(s, "\x00\x00\x00");
    }

    /// The generation range covers the whole mask: a mask holding only the
    /// highest possible bit conforms every character to it.
    function testConformStringHighBitOnlyMask() external pure {
        // A fresh string is all null bytes, none of which are in the mask.
        string memory s = new string(64);
        LibConformString.conformStringToMask(s, 1 << 0xFF);
        for (uint256 i = 0; i < bytes(s).length; i++) {
            assertEq(uint8(bytes(s)[i]), 0xFF);
        }
    }

    /// Every conformed character has its bit set in the mask: with two mask
    /// bits, one above the ASCII range, every character lands on one of the
    /// two.
    function testConformStringSparseHighMask() external pure {
        uint256 mask = (1 << 0x41) | (1 << 0xC3);
        string memory s = new string(64);
        LibConformString.conformStringToMask(s, mask);
        for (uint256 i = 0; i < bytes(s).length; i++) {
            uint256 char = uint256(uint8(bytes(s)[i]));
            assertTrue(char == 0x41 || char == 0xC3);
        }
    }

    /// Conforming is deterministic: the same input string and mask always
    /// produce the same output, regardless of surrounding memory state.
    function testConformStringDeterminism(string memory a, uint256 mask) external pure {
        vm.assume(mask != 0);
        string memory orig = string(bytes.concat(bytes(a)));
        LibConformString.conformStringToMask(a, mask);
        string memory b = string(bytes.concat(bytes(orig)));
        LibConformString.conformStringToMask(b, mask);
        assertEq(a, b);
    }

    /// Expected value comes from a keccak walk computed with cast, outside the
    /// implementation: each candidate is the first byte of
    /// keccak256(abi.encode(char, seed)) modulo the mask's bit length (0x21
    /// for whitespace), walked until a candidate lands in the mask.
    function testConformStringKnownWalk() external pure {
        string memory s = "a";
        LibConformString.conformStringToMask(s, CMASK_WHITESPACE);
        assertEq(uint8(bytes(s)[0]), 0x0D);
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
        // forge-lint: disable-next-line(unsafe-typecast)
        assertEq(uint8(bytes(s)[0]), uint8(bytes1("0")));
        // forge-lint: disable-next-line(unsafe-typecast)
        assertEq(uint8(bytes(s)[1]), uint8(bytes1("f")));
        // forge-lint: disable-next-line(unsafe-typecast)
        assertEq(uint8(bytes(s)[2]), uint8(bytes1("A")));
        // forge-lint: disable-next-line(unsafe-typecast)
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
        // forge-lint: disable-next-line(unsafe-typecast)
        assertEq(uint8(bytes(s)[3]), uint8(bytes1("a")));
        // forge-lint: disable-next-line(unsafe-typecast)
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
        // forge-lint: disable-next-line(unsafe-typecast)
        assertEq(uint8(bytes(s)[0]), uint8(bytes1("a")));
        // forge-lint: disable-next-line(unsafe-typecast)
        assertEq(uint8(bytes(s)[1]), uint8(bytes1("b")));
        // forge-lint: disable-next-line(unsafe-typecast)
        assertEq(uint8(bytes(s)[3]), uint8(bytes1("d")));
        uint256 char = uint256(uint8(bytes(s)[2]));
        // forge-lint: disable-next-line(incorrect-shift)
        assertTrue((1 << char) & uint256(CMASK_STRING_LITERAL_TAIL) == 0);
        // forge-lint: disable-next-line(unsafe-typecast)
        assertTrue(char != uint256(uint8(bytes1("\""))));
    }

    /// A double quote is corrupted to something else even though it is already
    /// outside the string literal tail mask.
    function testCorruptSingleCharQuote() external pure {
        string memory s = "\"\"";
        LibConformString.corruptSingleChar(s, 0);
        uint256 char = uint256(uint8(bytes(s)[0]));
        // forge-lint: disable-next-line(unsafe-typecast)
        assertTrue(char != uint256(uint8(bytes1("\""))));
        // forge-lint: disable-next-line(incorrect-shift)
        assertTrue((1 << char) & uint256(CMASK_STRING_LITERAL_TAIL) == 0);
        // The sibling byte is untouched.
        // forge-lint: disable-next-line(unsafe-typecast)
        assertEq(uint8(bytes(s)[1]), uint8(bytes1("\"")));
    }

    /// A byte that is already outside the string literal tail mask (and is not
    /// a double quote) is written back unchanged, including bytes above the
    /// ASCII range.
    function testCorruptSingleCharAlreadyInvalid() external pure {
        bytes memory b = hex"001f7f80ff";
        string memory s = string(b);
        LibConformString.corruptSingleChar(s, 0);
        LibConformString.corruptSingleChar(s, 1);
        LibConformString.corruptSingleChar(s, 2);
        LibConformString.corruptSingleChar(s, 3);
        LibConformString.corruptSingleChar(s, 4);
        assertEq(uint8(bytes(s)[0]), 0x00);
        assertEq(uint8(bytes(s)[1]), 0x1F);
        assertEq(uint8(bytes(s)[2]), 0x7F);
        assertEq(uint8(bytes(s)[3]), 0x80);
        assertEq(uint8(bytes(s)[4]), 0xFF);
    }

    /// The corruption alphabet covers the full byte range: sweeping every
    /// valid string literal tail byte as the starting character, every
    /// deterministic corruption result is outside the string literal tail
    /// mask and is not a double quote, and at least one result is a byte
    /// above the ASCII range.
    function testCorruptSingleCharHighByteReachable() external pure {
        uint256 highByteCount = 0;
        for (uint256 c = 0; c < 0x100; c++) {
            // forge-lint: disable-next-line(incorrect-shift)
            if ((1 << c) & uint256(CMASK_STRING_LITERAL_TAIL) == 0) {
                continue;
            }
            string memory s = new string(1);
            // forge-lint: disable-next-line(unsafe-typecast)
            bytes(s)[0] = bytes1(uint8(c));
            LibConformString.corruptSingleChar(s, 0);
            uint256 char = uint256(uint8(bytes(s)[0]));
            // forge-lint: disable-next-line(incorrect-shift)
            assertTrue((1 << char) & uint256(CMASK_STRING_LITERAL_TAIL) == 0);
            // forge-lint: disable-next-line(unsafe-typecast)
            assertTrue(char != uint256(uint8(bytes1("\""))));
            if (char >= 0x80) {
                highByteCount++;
            }
        }
        assertTrue(highByteCount > 0);
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

    /// A mask with bit 0 set does not swallow the seed: the seed selects
    /// among the conforming characters.
    function testCharFromMaskBitZeroSeedSelects() external pure {
        uint256 mask = 1 | (1 << 0x41);
        assertEq(uint8(LibConformString.charFromMask(0, mask)), 0);
        assertEq(uint8(LibConformString.charFromMask(0x41, mask)), 0x41);
    }

    /// The first candidate is the low byte of the seed, so any seed whose low
    /// byte is in the mask selects it directly: every set bit of the mask is
    /// selected by at least one seed, including bit 0.
    function testCharFromMaskLowByteSelected(uint256 seed, uint256 mask) external pure {
        uint256 char = seed & 0xFF;
        // forge-lint: disable-next-line(incorrect-shift)
        mask |= 1 << char;
        assertEq(uint8(LibConformString.charFromMask(seed, mask)), char);
    }

    /// When the low byte of the seed misses the mask, candidates reroll by
    /// hashing the candidate with the full seed, so seeds sharing a low byte
    /// still select independently. 0x01 is not a hex digit character, so both
    /// walks reroll. Expected values come from a keccak walk computed with
    /// cast, outside the implementation.
    function testCharFromMaskRerollUsesFullSeed() external pure {
        // forge-lint: disable-next-line(unsafe-typecast)
        assertEq(uint8(LibConformString.charFromMask(0x01, uint256(CMASK_HEX))), uint8(bytes1("d")));
        // forge-lint: disable-next-line(unsafe-typecast)
        assertEq(uint8(LibConformString.charFromMask(0x0101, uint256(CMASK_HEX))), uint8(bytes1("2")));
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
