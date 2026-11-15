// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title LibAffix
/// @notice Prefix and suffix checks that hash in place without copying.
library LibAffix {
    /// True if `data` begins with `prefix`.
    function startsWith(bytes memory data, bytes memory prefix) internal pure returns (bool) {
        bool result;
        assembly ("memory-safe") {
            let length := mload(prefix)
            if iszero(gt(length, mload(data))) {
                result := eq(keccak256(add(data, 0x20), length), keccak256(add(prefix, 0x20), length))
            }
        }
        return result;
    }

    /// True if `data` ends with `suffix`.
    function endsWith(bytes memory data, bytes memory suffix) internal pure returns (bool) {
        bool result;
        assembly ("memory-safe") {
            let length := mload(suffix)
            let dataLength := mload(data)
            if iszero(gt(length, dataLength)) {
                result := eq(
                    keccak256(add(add(data, 0x20), sub(dataLength, length)), length),
                    keccak256(add(suffix, 0x20), length)
                )
            }
        }
        return result;
    }

    /// True if `str` begins with `prefix`.
    function startsWith(string memory str, string memory prefix) internal pure returns (bool) {
        return startsWith(bytes(str), bytes(prefix));
    }

    /// True if `str` ends with `suffix`.
    function endsWith(string memory str, string memory suffix) internal pure returns (bool) {
        return endsWith(bytes(str), bytes(suffix));
    }
}
