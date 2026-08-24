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
    /// string until it finds one that is in the mask: characters whose bit is
    /// already set in the mask are kept as-is, all others are rerolled until
    /// they land in it, so every character of the conformed string has its bit
    /// set in the mask. Rerolled candidates are generated in the range
    /// [0, bit length of the mask), i.e. up to and including the mask's
    /// highest set bit, so the highest character in the mask is always
    /// generatable and the search always terminates.
    /// This function uses a simple linear probing algorithm to find a valid
    /// character. It is not the most efficient algorithm, but it is simple and
    /// effective for this use case.
    /// @param str The string to conform. This string is mutated in place.
    /// @param mask The character mask to conform to. Must be nonzero or
    /// `EmptyStringMask` is thrown.
    function conformStringToMask(string memory str, uint256 mask) internal pure {
        if (mask == 0) {
            revert EmptyStringMask();
        }

        // The reroll modulus is the bit length of the mask: the index of its
        // highest set bit plus one. Candidates are generated strictly below
        // it, which keeps them near the mask while still reaching every set
        // bit. Branchless binary search: each step tests whether the reduced
        // mask still has a bit at or above the step's width, and if so shifts
        // it down by that width and adds the width to the accumulated length.
        // `s` is the step's shift amount, either the width or zero.
        uint256 max;
        assembly ("memory-safe") {
            max := 1
            let m := mask
            let s := shl(7, iszero(iszero(shr(128, m))))
            m := shr(s, m)
            max := add(max, s)
            s := shl(6, iszero(iszero(shr(64, m))))
            m := shr(s, m)
            max := add(max, s)
            s := shl(5, iszero(iszero(shr(32, m))))
            m := shr(s, m)
            max := add(max, s)
            s := shl(4, iszero(iszero(shr(16, m))))
            m := shr(s, m)
            max := add(max, s)
            s := shl(3, iszero(iszero(shr(8, m))))
            m := shr(s, m)
            max := add(max, s)
            s := shl(2, iszero(iszero(shr(4, m))))
            m := shr(s, m)
            max := add(max, s)
            s := shl(1, iszero(iszero(shr(2, m))))
            m := shr(s, m)
            max := add(max, s)
            max := add(max, iszero(iszero(shr(1, m))))
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
                    // Bound candidates to the mask's bit length to give us a
                    // better chance of hitting the mask.
                    char := mod(byte(0, seed), max)
                }
            }
            // forge-lint: disable-next-line(unsafe-typecast)
            bytes(str)[i] = bytes1(uint8(char));
        }
    }

    /// Conforms the string to the full ASCII character set.
    function conformStringToAscii(string memory str) internal pure {
        conformStringToMask(str, type(uint128).max);
    }

    /// Conforms the string to ASCII hex digit characters.
    function conformStringToHexDigits(string memory str) internal pure {
        conformStringToMask(str, CMASK_HEX);
    }

    /// Conforms the string to printable characters that are valid string
    /// literal content.
    function conformValidPrintableStringContent(string memory str) internal pure {
        conformStringToMask(str, CMASK_STRING_LITERAL_TAIL);
    }

    /// Conforms the string to whitespace characters.
    function conformStringToWhitespace(string memory str) internal pure {
        conformStringToMask(str, CMASK_WHITESPACE);
    }

    /// Ensures the character at the specified index is not a valid character
    /// in a string literal (i.e., not in the CMASK_STRING_LITERAL_TAIL mask)
    /// and is not a double quote. This is primarily useful for testing
    /// purposes, e.g., to test that a parser correctly rejects invalid input.
    /// A character that is already invalid and not a double quote is kept
    /// as-is; any other character is replaced with a random such byte value.
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

    /// Deterministically selects a single character from the given mask using
    /// the provided seed. The first candidate is the low byte of the seed;
    /// while the candidate misses the mask it is rerolled as the top byte of
    /// the keccak256 hash of the candidate and the evolving seed. The result
    /// is always in the mask, and every set bit of the mask is selected by at
    /// least one seed (at minimum the seed equal to that bit's index).
    /// @param seed Selects which conforming character is produced.
    /// @param mask The character mask to conform to.
    /// @return The selected character. Always in the mask.
    function charFromMask(uint256 seed, uint256 mask) internal pure returns (bytes1) {
        if (mask == 0) {
            revert EmptyStringMask();
        }
        uint256 char = seed & 0xFF;
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
