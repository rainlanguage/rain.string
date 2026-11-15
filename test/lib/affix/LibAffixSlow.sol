// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// @title LibAffixSlow
/// @notice Byte-loop reference for prefix and suffix checks.
library LibAffixSlow {
    function startsWithSlow(bytes memory data, bytes memory prefix) internal pure returns (bool) {
        if (prefix.length > data.length) {
            return false;
        }
        for (uint256 i = 0; i < prefix.length; i++) {
            if (data[i] != prefix[i]) {
                return false;
            }
        }
        return true;
    }

    function endsWithSlow(bytes memory data, bytes memory suffix) internal pure returns (bool) {
        if (suffix.length > data.length) {
            return false;
        }
        uint256 offset = data.length - suffix.length;
        for (uint256 i = 0; i < suffix.length; i++) {
            if (data[offset + i] != suffix[i]) {
                return false;
            }
        }
        return true;
    }
}
