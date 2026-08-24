// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";

import {
    CMASK_NULL,
    CMASK_START_OF_HEADING,
    CMASK_START_OF_TEXT,
    CMASK_END_OF_TEXT,
    CMASK_END_OF_TRANSMISSION,
    CMASK_ENQUIRY,
    CMASK_ACKNOWLEDGE,
    CMASK_BELL,
    CMASK_BACKSPACE,
    CMASK_HORIZONTAL_TAB,
    CMASK_LINE_FEED,
    CMASK_VERTICAL_TAB,
    CMASK_FORM_FEED,
    CMASK_CARRIAGE_RETURN,
    CMASK_SHIFT_OUT,
    CMASK_SHIFT_IN,
    CMASK_DATA_LINK_ESCAPE,
    CMASK_DEVICE_CONTROL_1,
    CMASK_DEVICE_CONTROL_2,
    CMASK_DEVICE_CONTROL_3,
    CMASK_DEVICE_CONTROL_4,
    CMASK_NEGATIVE_ACKNOWLEDGE,
    CMASK_SYNCHRONOUS_IDLE,
    CMASK_END_OF_TRANSMISSION_BLOCK,
    CMASK_CANCEL,
    CMASK_END_OF_MEDIUM,
    CMASK_SUBSTITUTE,
    CMASK_ESCAPE,
    CMASK_FILE_SEPARATOR,
    CMASK_GROUP_SEPARATOR,
    CMASK_RECORD_SEPARATOR,
    CMASK_UNIT_SEPARATOR,
    CMASK_SPACE,
    CMASK_EXCLAMATION_MARK,
    CMASK_QUOTATION_MARK,
    CMASK_NUMBER_SIGN,
    CMASK_DOLLAR_SIGN,
    CMASK_PERCENT_SIGN,
    CMASK_AMPERSAND,
    CMASK_APOSTROPHE,
    CMASK_LEFT_PAREN,
    CMASK_RIGHT_PAREN,
    CMASK_ASTERISK,
    CMASK_PLUS_SIGN,
    CMASK_COMMA,
    CMASK_DASH,
    CMASK_FULL_STOP,
    CMASK_SLASH,
    CMASK_ZERO,
    CMASK_ONE,
    CMASK_TWO,
    CMASK_THREE,
    CMASK_FOUR,
    CMASK_FIVE,
    CMASK_SIX,
    CMASK_SEVEN,
    CMASK_EIGHT,
    CMASK_NINE,
    CMASK_COLON,
    CMASK_SEMICOLON,
    CMASK_LESS_THAN_SIGN,
    CMASK_EQUALS_SIGN,
    CMASK_GREATER_THAN_SIGN,
    CMASK_QUESTION_MARK,
    CMASK_AT_SIGN,
    CMASK_UPPER_A,
    CMASK_UPPER_B,
    CMASK_UPPER_C,
    CMASK_UPPER_D,
    CMASK_UPPER_E,
    CMASK_UPPER_F,
    CMASK_UPPER_G,
    CMASK_UPPER_H,
    CMASK_UPPER_I,
    CMASK_UPPER_J,
    CMASK_UPPER_K,
    CMASK_UPPER_L,
    CMASK_UPPER_M,
    CMASK_UPPER_N,
    CMASK_UPPER_O,
    CMASK_UPPER_P,
    CMASK_UPPER_Q,
    CMASK_UPPER_R,
    CMASK_UPPER_S,
    CMASK_UPPER_T,
    CMASK_UPPER_U,
    CMASK_UPPER_V,
    CMASK_UPPER_W,
    CMASK_UPPER_X,
    CMASK_UPPER_Y,
    CMASK_UPPER_Z,
    CMASK_LEFT_SQUARE_BRACKET,
    CMASK_BACKSLASH,
    CMASK_RIGHT_SQUARE_BRACKET,
    CMASK_CIRCUMFLEX_ACCENT,
    CMASK_UNDERSCORE,
    CMASK_GRAVE_ACCENT,
    CMASK_LOWER_A,
    CMASK_LOWER_B,
    CMASK_LOWER_C,
    CMASK_LOWER_D,
    CMASK_LOWER_E,
    CMASK_LOWER_F,
    CMASK_LOWER_G,
    CMASK_LOWER_H,
    CMASK_LOWER_I,
    CMASK_LOWER_J,
    CMASK_LOWER_K,
    CMASK_LOWER_L,
    CMASK_LOWER_M,
    CMASK_LOWER_N,
    CMASK_LOWER_O,
    CMASK_LOWER_P,
    CMASK_LOWER_Q,
    CMASK_LOWER_R,
    CMASK_LOWER_S,
    CMASK_LOWER_T,
    CMASK_LOWER_U,
    CMASK_LOWER_V,
    CMASK_LOWER_W,
    CMASK_LOWER_X,
    CMASK_LOWER_Y,
    CMASK_LOWER_Z,
    CMASK_LEFT_CURLY_BRACKET,
    CMASK_VERTICAL_BAR,
    CMASK_RIGHT_CURLY_BRACKET,
    CMASK_TILDE,
    CMASK_DELETE,
    CMASK_PRINTABLE,
    CMASK_NUMERIC_0_9,
    CMASK_E_NOTATION,
    CMASK_DECIMAL_POINT,
    CMASK_NEGATIVE_SIGN,
    CMASK_LOWER_ALPHA_A_Z,
    CMASK_UPPER_ALPHA_A_Z,
    CMASK_LOWER_ALPHA_A_F,
    CMASK_UPPER_ALPHA_A_F,
    CMASK_HEX,
    CMASK_EOL,
    CMASK_LHS_RHS_DELIMITER,
    CMASK_EOS,
    CMASK_LHS_STACK_HEAD,
    CMASK_IDENTIFIER_HEAD,
    CMASK_RHS_WORD_HEAD,
    CMASK_IDENTIFIER_TAIL,
    CMASK_LHS_STACK_TAIL,
    CMASK_RHS_WORD_TAIL,
    CMASK_OPERAND_START,
    CMASK_OPERAND_END,
    CMASK_NOT_IDENTIFIER_TAIL,
    CMASK_WHITESPACE,
    CMASK_LHS_STACK_DELIMITER,
    CMASK_NUMERIC_LITERAL_HEAD,
    CMASK_STRING_LITERAL_HEAD,
    CMASK_SUB_PARSEABLE_LITERAL_HEAD,
    CMASK_SUB_PARSEABLE_LITERAL_END,
    CMASK_STRING_LITERAL_END,
    CMASK_STRING_LITERAL_TAIL,
    CMASK_LITERAL_HEAD,
    CMASK_COMMENT_HEAD,
    CMASK_INTERSTITIAL_HEAD,
    COMMENT_START_SEQUENCE,
    COMMENT_END_SEQUENCE,
    COMMENT_END_SEQUENCE_END,
    CMASK_LITERAL_HEX_DISPATCH,
    LITERAL_HEX_DISPATCH_START_SEQUENCE
} from "src/lib/parse/LibParseCMask.sol";
import {LibParseChar} from "src/lib/parse/LibParseChar.sol";
import {Pointer} from "rain-solmem-0.1.26/src/lib/LibPointer.sol";
import {LibBytes} from "rain-solmem-0.1.26/src/lib/LibBytes.sol";

/// @title LibParseCMaskTest
/// @notice Pins every character mask constant to its ASCII semantics. Expected
/// values are the ASCII codes from the ASCII table, written as raw bit
/// positions, and composite masks are rebuilt independently from their
/// documented character sets.
contract LibParseCMaskTest is Test {
    using LibBytes for bytes;

    /// Builds a mask with one bit set for every character code in the
    /// inclusive range [lo, hi].
    function rangeMask(uint256 lo, uint256 hi) internal pure returns (uint256 mask) {
        for (uint256 i = lo; i <= hi; i++) {
            mask |= 1 << i;
        }
    }

    /// ASCII control characters 0x00-0x1F.
    function testCMaskControlCharacters() external pure {
        assertEq(CMASK_NULL, 1 << 0x00);
        assertEq(CMASK_START_OF_HEADING, 1 << 0x01);
        assertEq(CMASK_START_OF_TEXT, 1 << 0x02);
        assertEq(CMASK_END_OF_TEXT, 1 << 0x03);
        assertEq(CMASK_END_OF_TRANSMISSION, 1 << 0x04);
        assertEq(CMASK_ENQUIRY, 1 << 0x05);
        assertEq(CMASK_ACKNOWLEDGE, 1 << 0x06);
        assertEq(CMASK_BELL, 1 << 0x07);
        assertEq(CMASK_BACKSPACE, 1 << 0x08);
        assertEq(CMASK_HORIZONTAL_TAB, 1 << 0x09);
        assertEq(CMASK_LINE_FEED, 1 << 0x0A);
        assertEq(CMASK_VERTICAL_TAB, 1 << 0x0B);
        assertEq(CMASK_FORM_FEED, 1 << 0x0C);
        assertEq(CMASK_CARRIAGE_RETURN, 1 << 0x0D);
        assertEq(CMASK_SHIFT_OUT, 1 << 0x0E);
        assertEq(CMASK_SHIFT_IN, 1 << 0x0F);
        assertEq(CMASK_DATA_LINK_ESCAPE, 1 << 0x10);
        assertEq(CMASK_DEVICE_CONTROL_1, 1 << 0x11);
        assertEq(CMASK_DEVICE_CONTROL_2, 1 << 0x12);
        assertEq(CMASK_DEVICE_CONTROL_3, 1 << 0x13);
        assertEq(CMASK_DEVICE_CONTROL_4, 1 << 0x14);
        assertEq(CMASK_NEGATIVE_ACKNOWLEDGE, 1 << 0x15);
        assertEq(CMASK_SYNCHRONOUS_IDLE, 1 << 0x16);
        assertEq(CMASK_END_OF_TRANSMISSION_BLOCK, 1 << 0x17);
        assertEq(CMASK_CANCEL, 1 << 0x18);
        assertEq(CMASK_END_OF_MEDIUM, 1 << 0x19);
        assertEq(CMASK_SUBSTITUTE, 1 << 0x1A);
        assertEq(CMASK_ESCAPE, 1 << 0x1B);
        assertEq(CMASK_FILE_SEPARATOR, 1 << 0x1C);
        assertEq(CMASK_GROUP_SEPARATOR, 1 << 0x1D);
        assertEq(CMASK_RECORD_SEPARATOR, 1 << 0x1E);
        assertEq(CMASK_UNIT_SEPARATOR, 1 << 0x1F);
    }

    /// ASCII punctuation and digits 0x20-0x40.
    function testCMaskPunctuationAndDigits() external pure {
        assertEq(CMASK_SPACE, 1 << 0x20);
        assertEq(CMASK_EXCLAMATION_MARK, 1 << 0x21);
        assertEq(CMASK_QUOTATION_MARK, 1 << 0x22);
        assertEq(CMASK_NUMBER_SIGN, 1 << 0x23);
        assertEq(CMASK_DOLLAR_SIGN, 1 << 0x24);
        assertEq(CMASK_PERCENT_SIGN, 1 << 0x25);
        assertEq(CMASK_AMPERSAND, 1 << 0x26);
        assertEq(CMASK_APOSTROPHE, 1 << 0x27);
        assertEq(CMASK_LEFT_PAREN, 1 << 0x28);
        assertEq(CMASK_RIGHT_PAREN, 1 << 0x29);
        assertEq(CMASK_ASTERISK, 1 << 0x2A);
        assertEq(CMASK_PLUS_SIGN, 1 << 0x2B);
        assertEq(CMASK_COMMA, 1 << 0x2C);
        assertEq(CMASK_DASH, 1 << 0x2D);
        assertEq(CMASK_FULL_STOP, 1 << 0x2E);
        assertEq(CMASK_SLASH, 1 << 0x2F);
        assertEq(CMASK_ZERO, 1 << 0x30);
        assertEq(CMASK_ONE, 1 << 0x31);
        assertEq(CMASK_TWO, 1 << 0x32);
        assertEq(CMASK_THREE, 1 << 0x33);
        assertEq(CMASK_FOUR, 1 << 0x34);
        assertEq(CMASK_FIVE, 1 << 0x35);
        assertEq(CMASK_SIX, 1 << 0x36);
        assertEq(CMASK_SEVEN, 1 << 0x37);
        assertEq(CMASK_EIGHT, 1 << 0x38);
        assertEq(CMASK_NINE, 1 << 0x39);
        assertEq(CMASK_COLON, 1 << 0x3A);
        assertEq(CMASK_SEMICOLON, 1 << 0x3B);
        assertEq(CMASK_LESS_THAN_SIGN, 1 << 0x3C);
        assertEq(CMASK_EQUALS_SIGN, 1 << 0x3D);
        assertEq(CMASK_GREATER_THAN_SIGN, 1 << 0x3E);
        assertEq(CMASK_QUESTION_MARK, 1 << 0x3F);
        assertEq(CMASK_AT_SIGN, 1 << 0x40);
    }

    /// ASCII uppercase letters and punctuation 0x41-0x60.
    function testCMaskUpperAlpha() external pure {
        assertEq(CMASK_UPPER_A, 1 << 0x41);
        assertEq(CMASK_UPPER_B, 1 << 0x42);
        assertEq(CMASK_UPPER_C, 1 << 0x43);
        assertEq(CMASK_UPPER_D, 1 << 0x44);
        assertEq(CMASK_UPPER_E, 1 << 0x45);
        assertEq(CMASK_UPPER_F, 1 << 0x46);
        assertEq(CMASK_UPPER_G, 1 << 0x47);
        assertEq(CMASK_UPPER_H, 1 << 0x48);
        assertEq(CMASK_UPPER_I, 1 << 0x49);
        assertEq(CMASK_UPPER_J, 1 << 0x4A);
        assertEq(CMASK_UPPER_K, 1 << 0x4B);
        assertEq(CMASK_UPPER_L, 1 << 0x4C);
        assertEq(CMASK_UPPER_M, 1 << 0x4D);
        assertEq(CMASK_UPPER_N, 1 << 0x4E);
        assertEq(CMASK_UPPER_O, 1 << 0x4F);
        assertEq(CMASK_UPPER_P, 1 << 0x50);
        assertEq(CMASK_UPPER_Q, 1 << 0x51);
        assertEq(CMASK_UPPER_R, 1 << 0x52);
        assertEq(CMASK_UPPER_S, 1 << 0x53);
        assertEq(CMASK_UPPER_T, 1 << 0x54);
        assertEq(CMASK_UPPER_U, 1 << 0x55);
        assertEq(CMASK_UPPER_V, 1 << 0x56);
        assertEq(CMASK_UPPER_W, 1 << 0x57);
        assertEq(CMASK_UPPER_X, 1 << 0x58);
        assertEq(CMASK_UPPER_Y, 1 << 0x59);
        assertEq(CMASK_UPPER_Z, 1 << 0x5A);
        assertEq(CMASK_LEFT_SQUARE_BRACKET, 1 << 0x5B);
        assertEq(CMASK_BACKSLASH, 1 << 0x5C);
        assertEq(CMASK_RIGHT_SQUARE_BRACKET, 1 << 0x5D);
        assertEq(CMASK_CIRCUMFLEX_ACCENT, 1 << 0x5E);
        assertEq(CMASK_UNDERSCORE, 1 << 0x5F);
        assertEq(CMASK_GRAVE_ACCENT, 1 << 0x60);
    }

    /// ASCII lowercase letters and punctuation 0x61-0x7F.
    function testCMaskLowerAlpha() external pure {
        assertEq(CMASK_LOWER_A, 1 << 0x61);
        assertEq(CMASK_LOWER_B, 1 << 0x62);
        assertEq(CMASK_LOWER_C, 1 << 0x63);
        assertEq(CMASK_LOWER_D, 1 << 0x64);
        assertEq(CMASK_LOWER_E, 1 << 0x65);
        assertEq(CMASK_LOWER_F, 1 << 0x66);
        assertEq(CMASK_LOWER_G, 1 << 0x67);
        assertEq(CMASK_LOWER_H, 1 << 0x68);
        assertEq(CMASK_LOWER_I, 1 << 0x69);
        assertEq(CMASK_LOWER_J, 1 << 0x6A);
        assertEq(CMASK_LOWER_K, 1 << 0x6B);
        assertEq(CMASK_LOWER_L, 1 << 0x6C);
        assertEq(CMASK_LOWER_M, 1 << 0x6D);
        assertEq(CMASK_LOWER_N, 1 << 0x6E);
        assertEq(CMASK_LOWER_O, 1 << 0x6F);
        assertEq(CMASK_LOWER_P, 1 << 0x70);
        assertEq(CMASK_LOWER_Q, 1 << 0x71);
        assertEq(CMASK_LOWER_R, 1 << 0x72);
        assertEq(CMASK_LOWER_S, 1 << 0x73);
        assertEq(CMASK_LOWER_T, 1 << 0x74);
        assertEq(CMASK_LOWER_U, 1 << 0x75);
        assertEq(CMASK_LOWER_V, 1 << 0x76);
        assertEq(CMASK_LOWER_W, 1 << 0x77);
        assertEq(CMASK_LOWER_X, 1 << 0x78);
        assertEq(CMASK_LOWER_Y, 1 << 0x79);
        assertEq(CMASK_LOWER_Z, 1 << 0x7A);
        assertEq(CMASK_LEFT_CURLY_BRACKET, 1 << 0x7B);
        assertEq(CMASK_VERTICAL_BAR, 1 << 0x7C);
        assertEq(CMASK_RIGHT_CURLY_BRACKET, 1 << 0x7D);
        assertEq(CMASK_TILDE, 1 << 0x7E);
        assertEq(CMASK_DELETE, 1 << 0x7F);
    }

    /// Alphanumeric range masks rebuilt from their ASCII ranges.
    function testCMaskAlphaNumericRanges() external pure {
        assertEq(CMASK_NUMERIC_0_9, rangeMask(0x30, 0x39));
        assertEq(CMASK_LOWER_ALPHA_A_Z, rangeMask(0x61, 0x7A));
        assertEq(CMASK_UPPER_ALPHA_A_Z, rangeMask(0x41, 0x5A));
        assertEq(CMASK_LOWER_ALPHA_A_F, rangeMask(0x61, 0x66));
        assertEq(CMASK_UPPER_ALPHA_A_F, rangeMask(0x41, 0x46));
        assertEq(CMASK_HEX, rangeMask(0x30, 0x39) | rangeMask(0x61, 0x66) | rangeMask(0x41, 0x46));
    }

    /// Printable ASCII is space up to tilde: DEL 0x7F is excluded and no bit
    /// at or above 0x80 is set.
    function testCMaskPrintable() external pure {
        assertEq(CMASK_PRINTABLE, rangeMask(0x20, 0x7E));
        // The string literal tail is every printable character except the
        // double quote that terminates the string.
        assertEq(CMASK_STRING_LITERAL_TAIL, rangeMask(0x20, 0x7E) & ~uint256(1 << 0x22));
    }

    /// Rainlang structural character masks.
    function testCMaskRainlangStructure() external pure {
        assertEq(CMASK_EOL, 1 << 0x2C); // ,
        assertEq(CMASK_LHS_RHS_DELIMITER, 1 << 0x3A); // :
        assertEq(CMASK_EOS, 1 << 0x3B); // ;
        assertEq(CMASK_OPERAND_START, 1 << 0x3C); // <
        assertEq(CMASK_OPERAND_END, 1 << 0x3E); // >
        assertEq(CMASK_COMMENT_HEAD, 1 << 0x2F); // /

        uint256 lowerAlpha = rangeMask(0x61, 0x7A);
        assertEq(CMASK_LHS_STACK_HEAD, lowerAlpha | (1 << 0x5F)); // a-z _
        assertEq(CMASK_IDENTIFIER_HEAD, lowerAlpha); // a-z
        assertEq(CMASK_RHS_WORD_HEAD, lowerAlpha); // a-z

        uint256 identifierTail = lowerAlpha | rangeMask(0x30, 0x39) | (1 << 0x2D); // a-z 0-9 -
        assertEq(CMASK_IDENTIFIER_TAIL, identifierTail);
        assertEq(CMASK_LHS_STACK_TAIL, identifierTail);
        assertEq(CMASK_RHS_WORD_TAIL, identifierTail);
        // The complement is relative to the 128 bit mask domain.
        assertEq(CMASK_NOT_IDENTIFIER_TAIL, ~identifierTail & type(uint128).max);

        uint256 whitespace = (1 << 0x09) | (1 << 0x0A) | (1 << 0x0D) | (1 << 0x20); // \t \n \r space
        assertEq(CMASK_WHITESPACE, whitespace);
        assertEq(CMASK_LHS_STACK_DELIMITER, whitespace);
        assertEq(CMASK_INTERSTITIAL_HEAD, whitespace | (1 << 0x2F)); // whitespace /
    }

    /// Rainlang literal character masks.
    function testCMaskLiterals() external pure {
        assertEq(CMASK_E_NOTATION, (1 << 0x65) | (1 << 0x45)); // e E
        assertEq(CMASK_DECIMAL_POINT, 1 << 0x2E); // .
        assertEq(CMASK_NEGATIVE_SIGN, 1 << 0x2D); // -
        assertEq(CMASK_STRING_LITERAL_HEAD, 1 << 0x22); // "
        assertEq(CMASK_STRING_LITERAL_END, 1 << 0x22); // "
        assertEq(CMASK_SUB_PARSEABLE_LITERAL_HEAD, 1 << 0x5B); // [
        assertEq(CMASK_SUB_PARSEABLE_LITERAL_END, 1 << 0x5D); // ]

        uint256 digits = rangeMask(0x30, 0x39);
        assertEq(CMASK_NUMERIC_LITERAL_HEAD, digits | (1 << 0x2D)); // 0-9 -
        assertEq(CMASK_LITERAL_HEAD, digits | (1 << 0x2D) | (1 << 0x22) | (1 << 0x5B)); // 0-9 - " [
        assertEq(CMASK_LITERAL_HEX_DISPATCH, (1 << 0x30) | (1 << 0x78)); // 0 x
    }

    /// Two-byte sequences and their derived values.
    function testCMaskSequences() external pure {
        assertEq(COMMENT_START_SEQUENCE, 0x2F2A); // "/*"
        assertEq(COMMENT_END_SEQUENCE, 0x2A2F); // "*/"
        assertEq(COMMENT_END_SEQUENCE_END, 0x2F); // "/"
        assertEq(LITERAL_HEX_DISPATCH_START_SEQUENCE, 0x3078); // "0x"
    }

    /// Bytes 0x80-0xFF are in neither CMASK_IDENTIFIER_TAIL nor
    /// CMASK_NOT_IDENTIFIER_TAIL: the complement is taken at uint128 width,
    /// so the two masks together cover only the 7-bit ASCII domain and do not
    /// partition the full byte domain.
    function testCMaskIdentifierTailHighBytesInNeitherMask() external pure {
        for (uint256 c = 0x80; c <= 0xFF; c++) {
            assertEq((1 << c) & (uint256(CMASK_IDENTIFIER_TAIL) | uint256(CMASK_NOT_IDENTIFIER_TAIL)), 0);
        }
    }

    /// The consumer-visible form of the 7-bit ASCII mask domain: reading any
    /// byte 0x80-0xFF through LibParseChar.isMask matches neither
    /// CMASK_IDENTIFIER_TAIL nor CMASK_NOT_IDENTIFIER_TAIL, and is never
    /// printable.
    function testCMaskHighBytesNeverMatchIsMask() external pure {
        for (uint256 c = 0x80; c <= 0xFF; c++) {
            bytes memory data = new bytes(1);
            // forge-lint: disable-next-line(unsafe-typecast)
            data[0] = bytes1(uint8(c));
            uint256 cursor = Pointer.unwrap(data.dataPointer());
            uint256 end = Pointer.unwrap(data.endDataPointer());
            assertEq(LibParseChar.isMask(cursor, end, uint256(CMASK_IDENTIFIER_TAIL)), 0);
            assertEq(LibParseChar.isMask(cursor, end, uint256(CMASK_NOT_IDENTIFIER_TAIL)), 0);
            assertEq(LibParseChar.isMask(cursor, end, uint256(CMASK_PRINTABLE)), 0);
        }
    }
}
