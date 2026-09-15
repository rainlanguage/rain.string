// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title LibStringSet
/// @notice Membership over a `string[]`, for an assertion about a set whose
/// order it does not fix.
///
/// Solidity has no string equality and no set, so a caller that wants "this
/// list holds this string" writes the comparison itself. WHY a caller wants
/// membership rather than an index or an ordering is the caller's own reasoning
/// and stays with the caller; what happens here is only the comparison, which is
/// the same comparison wherever it is asked for.
library LibStringSet {
    /// Whether `haystack` holds `needle`.
    ///
    /// Compared by length first and then by the bytes themselves. Length is one
    /// word already in hand, so an element that cannot be equal costs a single
    /// comparison and is never read further; hashing instead pays for every
    /// element's whole content before it can say the same thing.
    ///
    /// The bytes past a string's length are NOT guaranteed to be zero, so the
    /// final partial word is compared under a mask that keeps only the bytes the
    /// length claims. Comparing that word whole would report two equal strings
    /// as different whenever whatever built them left different remains behind.
    /// @param haystack The strings to search.
    /// @param needle The string to find.
    /// @return held Whether it is present.
    function holds(string[] memory haystack, string memory needle) internal pure returns (bool held) {
        assembly ("memory-safe") {
            let needleLength := mload(needle)
            let needleData := add(needle, 0x20)
            let wholeWords := shr(5, needleLength)
            let remainder := and(needleLength, 0x1f)
            // Keeps the top `remainder` bytes. Unused when the length is a whole
            // number of words, which is why a shift of 256 reading as zero here
            // is not a case.
            let tailMask := shl(mul(8, sub(0x20, remainder)), not(0))

            let end := add(haystack, add(0x20, mul(0x20, mload(haystack))))
            for { let cursor := add(haystack, 0x20) } lt(cursor, end) { cursor := add(cursor, 0x20) } {
                let candidate := mload(cursor)
                if eq(mload(candidate), needleLength) {
                    let candidateData := add(candidate, 0x20)
                    let equal := 1

                    for { let offset := 0 } lt(offset, mul(wholeWords, 0x20)) { offset := add(offset, 0x20) } {
                        if iszero(eq(mload(add(needleData, offset)), mload(add(candidateData, offset)))) {
                            equal := 0
                            break
                        }
                    }

                    if and(equal, iszero(iszero(remainder))) {
                        let offset := mul(wholeWords, 0x20)
                        let needleTail := and(mload(add(needleData, offset)), tailMask)
                        let candidateTail := and(mload(add(candidateData, offset)), tailMask)
                        if iszero(eq(needleTail, candidateTail)) { equal := 0 }
                    }

                    if equal {
                        held := 1
                        break
                    }
                }
            }
        }
    }
}
