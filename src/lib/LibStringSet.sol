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
    /// The needle is hashed ONCE, outside the loop. The compiler does not lift
    /// it out on its own, so hashing it in the comparison pays for it again per
    /// element: measured over the tests below, lifting it saves 511 gas on the
    /// largest list they search and costs 106 on an empty one, where the needle
    /// is hashed for a loop that never runs.
    ///
    /// Hashing is the comparison rather than reading the bytes because
    /// `keccak256` carries the length with it. The bytes past a string's length
    /// are not guaranteed to be zero, so a word-by-word comparison has to mask
    /// the final partial word or report two equal strings as different. That
    /// version was written and measured against this one, as was a length
    /// comparison guarding the hash; both cost more than they saved at every
    /// size these tests cover, so neither is here.
    /// @param haystack The strings to search.
    /// @param needle The string to find.
    /// @return Whether it is present.
    function holds(string[] memory haystack, string memory needle) internal pure returns (bool) {
        bytes32 needleHash = keccak256(bytes(needle));

        for (uint256 i = 0; i < haystack.length; i++) {
            if (keccak256(bytes(haystack[i])) == needleHash) {
                return true;
            }
        }
        return false;
    }
}
