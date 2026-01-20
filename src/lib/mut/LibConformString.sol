// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.18;

import {CMASK_STRING_LITERAL_TAIL, CMASK_HEX, CMASK_WHITESPACE} from "../parse/LibParseCMask.sol";
import {EmptyStringMask} from "../../error/ErrConform.sol";

/// @title LibConformString
/// @notice A library for conforming strings to character masks. This involves
/// mutating the string in place by directly modifying the bytes with assembly.
/// This is designed to be used in a test environment to generate strings that
/// originate from a fuzzer, but the SUT expects or can only handle a subset of
/// possible characters. For example, the SUT may only accept ASCII characters
/// or only accept hex digits.
library LibConformString {
    /// Main workhorse function for the lib. Brute forces each character in the
    /// string until it finds one that is in the mask. The `max` parameter is
    /// used to limit the range of characters that are generated. For example, if
    /// the mask only includes ASCII characters, then `max` should be set to 128
    /// to avoid generating characters outside of the ASCII range.
    /// This function uses a simple linear probing algorithm to find a valid
    /// character. It is not the most efficient algorithm, but it is simple and
    /// effective for this use case.
    /// @param str The string to conform. This string is mutated in place.
    /// @param mask The character mask to conform to.
    /// @param max The maximum character value to generate. This is used to
    /// limit the range of characters that are generated.
    function conformStringToMask(string memory str, uint256 mask, uint256 max) internal pure {
        if (mask == 0) {
            revert EmptyStringMask();
        }
        uint256 seed = 0;
        for (uint256 i = 0; i < bytes(str).length; i++) {
            uint256 char = uint256(uint8(bytes(str)[i]));
            // If the char is not in the mask, roll it.
            // forge-lint: disable-next-line(incorrect-shift)
            while (1 << char & mask == 0) {
                assembly ("memory-safe") {
                    mstore(0, char)
                    mstore(0x20, seed)
                    seed := keccak256(0, 0x40)
                    // Eliminate everything out of range to give us a better
                    // chance of hitting the mask.
                    char := mod(byte(0, seed), max)
                }
            }
            // forge-lint: disable-next-line(unsafe-typecast)
            bytes(str)[i] = bytes1(uint8(char));
        }
    }

    /// Overload that assumes ASCII range.
    function conformStringToMask(string memory str, uint256 mask) internal pure {
        // Assume that we want to restrict to ASCII range.
        conformStringToMask(str, mask, 0x80);
    }

    /// Overload that explicitly conforms to ASCII.
    function conformStringToAscii(string memory str) internal pure {
        conformStringToMask(str, type(uint128).max, 0x80);
    }

    /// Overload that explicitly conforms to ASCII hex digits.
    function conformStringToHexDigits(string memory str) internal pure {
        // 0x7B is '{' which is just after 'z'.
        conformStringToMask(str, CMASK_HEX, 0x7B);
    }

    /// Overload that explicitly conforms to printable ASCII characters.
    function conformValidPrintableStringContent(string memory str) internal pure {
        conformStringToMask(str, CMASK_STRING_LITERAL_TAIL, 0x80);
    }

    /// Overload that explicitly conforms to whitespace characters.
    function conformStringToWhitespace(string memory str) internal pure {
        // 33 is ! which is after space.
        conformStringToMask(str, CMASK_WHITESPACE, 33);
    }

    /// Corrupts a single character in the string to some random byte value in
    /// a rather inefficient way. This is primarily useful for testing
    /// purposes, e.g., to test that a parser correctly rejects invalid input.
    /// The character at the specified index is replaced with a random byte
    /// value that is not a valid character in a string literal (i.e., not in
    /// the CMASK_STRING_LITERAL_TAIL mask) and is not a double quote.
    /// @param str The string to corrupt. This string is mutated in place.
    /// @param index The index of the character to corrupt.
    function corruptSingleChar(string memory str, uint256 index) internal pure {
        uint256 char = uint256(uint8(bytes(str)[index]));
        uint256 seed = 0;
        // forge-lint: disable-next-line(unsafe-typecast,incorrect-shift)
        while (1 << char & ~CMASK_STRING_LITERAL_TAIL == 0 || char == uint8(bytes1("\""))) {
            assembly ("memory-safe") {
                mstore(0, char)
                mstore(0x20, seed)
                seed := keccak256(0, 0x40)
                char := byte(0, seed)
            }
        }
        // forge-lint: disable-next-line(unsafe-typecast)
        bytes(str)[index] = bytes1(uint8(char));
    }

    /// Generates a single character from the given mask using the provided
    /// seed. This is useful for generating random characters that conform to a
    /// specific character set.
    /// @param seed The seed to use for generating the character.
    /// @param mask The character mask to conform to.
    /// @return The generated character.
    function charFromMask(uint256 seed, uint256 mask) internal pure returns (bytes1) {
        if (mask == 0) {
            revert EmptyStringMask();
        }
        uint256 char = 0;
        // forge-lint: disable-next-line(incorrect-shift)
        while (1 << char & mask == 0) {
            assembly ("memory-safe") {
                mstore(0, char)
                mstore(0x20, seed)
                seed := keccak256(0, 0x40)
                char := byte(0, seed)
            }
        }
        // forge-lint: disable-next-line(unsafe-typecast)
        return bytes1(uint8(char));
    }
}
