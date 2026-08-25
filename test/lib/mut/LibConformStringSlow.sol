// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title LibConformStringSlow
/// @notice Naive reference for the conform walk written from the documented
/// spec: rerolled candidates are the top byte of keccak256(candidate, seed)
/// mod the mask's bit length, with the seed evolving across rerolls and
/// characters.
library LibConformStringSlow {
    function bitLengthSlow(uint256 mask) internal pure returns (uint256 length) {
        while (mask != 0) {
            length++;
            mask >>= 1;
        }
    }

    function conformSlow(string memory str, uint256 mask) internal pure {
        uint256 max = bitLengthSlow(mask);
        uint256 seed = 0;
        for (uint256 i = 0; i < bytes(str).length; i++) {
            uint256 char = uint256(uint8(bytes(str)[i]));
            // forge-lint: disable-next-line(incorrect-shift)
            while ((1 << char) & mask == 0) {
                seed = uint256(keccak256(abi.encode(char, seed)));
                char = (seed >> 248) % max;
            }
            // forge-lint: disable-next-line(unsafe-typecast)
            bytes(str)[i] = bytes1(uint8(char));
        }
    }
}
