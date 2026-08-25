// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title LibTestString
/// @notice String construction helpers for tests.
library LibTestString {
    /// Builds a string of `length` ASCII `0` bytes.
    /// @param length The number of `0` bytes in the string.
    /// @return str The string of `length` ASCII `0` bytes.
    function zeros(uint256 length) internal pure returns (string memory str) {
        str = new string(length);
        for (uint256 i = 0; i < length; i++) {
            bytes(str)[i] = "0";
        }
    }
}
