// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title LibTestBytes
/// @notice Bytes construction helpers for tests.
library LibTestBytes {
    /// Builds `length` bytes counting up from `start`.
    function sequence(uint256 length, uint8 start) internal pure returns (bytes memory b) {
        b = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            b[i] = bytes1(uint8((start + i) & 0xff));
        }
    }

    /// Copies `data[start:end]`.
    function slice(bytes memory data, uint256 start, uint256 end) internal pure returns (bytes memory b) {
        b = new bytes(end - start);
        for (uint256 i = 0; i < b.length; i++) {
            b[i] = data[start + i];
        }
    }

    /// Copies `content` into allocated memory followed by 32 bytes of `fill`,
    /// so any read past the returned length sees `fill`.
    function trailedBy(bytes memory content, bytes1 fill) internal pure returns (bytes memory b) {
        b = new bytes(content.length + 0x20);
        for (uint256 i = 0; i < content.length; i++) {
            b[i] = content[i];
        }
        for (uint256 i = content.length; i < b.length; i++) {
            b[i] = fill;
        }
        uint256 length = content.length;
        assembly ("memory-safe") {
            mstore(b, length)
        }
    }

    /// Copies `content` and truncates the copy to `length`, so the memory past
    /// the returned length still holds the rest of `content`.
    function truncated(bytes memory content, uint256 length) internal pure returns (bytes memory b) {
        b = bytes.concat(content);
        assembly ("memory-safe") {
            mstore(b, length)
        }
    }
}
