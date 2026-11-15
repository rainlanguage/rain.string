// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.2/src/Test.sol";

import {LibAffix} from "../../../../src/lib/affix/LibAffix.sol";
import {LibAffixSlow} from "../../../lib/affix/LibAffixSlow.sol";
import {LibTestBytes} from "../../../lib/LibTestBytes.sol";

contract LibAffixEndsWithTest is Test {
    function boundaryLengths() internal pure returns (uint256[7] memory) {
        return [uint256(0), 1, 31, 32, 33, 64, 65];
    }

    function testEndsWithReference(bytes memory data, bytes memory suffix) external pure {
        assertEq(LibAffix.endsWith(data, suffix), LibAffixSlow.endsWithSlow(data, suffix));
    }

    function testEndsWithOwnSuffix(bytes memory data, uint256 length) external pure {
        length = bound(length, 0, data.length);
        bytes memory suffix = LibTestBytes.trailedBy(LibTestBytes.slice(data, data.length - length, data.length), 0xEE);
        assertTrue(LibAffixSlow.endsWithSlow(data, suffix));
        assertTrue(LibAffix.endsWith(data, suffix));
    }

    function testEndsWithCorruptedSuffix(bytes memory data, uint256 length, uint256 index, uint8 mask) external pure {
        vm.assume(data.length > 0);
        vm.assume(mask != 0);
        length = bound(length, 1, data.length);
        index = bound(index, 0, length - 1);
        bytes memory suffix = LibTestBytes.slice(data, data.length - length, data.length);
        suffix[index] ^= bytes1(mask);
        assertFalse(LibAffixSlow.endsWithSlow(data, suffix));
        assertFalse(LibAffix.endsWith(data, suffix));
    }

    function testEndsWithEmptySuffix(bytes memory data) external pure {
        assertTrue(LibAffix.endsWith(data, ""));
    }

    function testEndsWithEmptyData(bytes memory suffix) external pure {
        assertEq(LibAffix.endsWith("", suffix), suffix.length == 0);
    }

    function testEndsWithWholeData(bytes memory data) external pure {
        assertTrue(LibAffix.endsWith(data, bytes.concat(data)));
    }

    /// Unguarded, the suffix slice offset wraps to before `data`'s content,
    /// where its length word sits. The suffix matches those length-word bytes
    /// followed by the content, so only the length check rejects it.
    function testEndsWithLongerSuffix(bytes memory data, uint256 extra) external pure {
        extra = bound(extra, 1, 0x20);
        bytes memory suffix = bytes.concat(LibTestBytes.slice(abi.encode(data.length), 0x20 - extra, 0x20), data);
        assertFalse(LibAffixSlow.endsWithSlow(data, suffix));
        assertFalse(LibAffix.endsWith(data, suffix));
    }

    function testEndsWithLongerByOne() external pure {
        uint256[7] memory lengths = boundaryLengths();
        for (uint256 i = 0; i < lengths.length; i++) {
            bytes memory data = LibTestBytes.sequence(lengths[i], 1);
            bytes memory suffix = bytes.concat(bytes1(uint8(lengths[i])), data);
            assertFalse(LibAffix.endsWith(data, suffix));
        }
    }

    /// Different non-zero fills follow `data` and `suffix`, so any read past
    /// either length changes the result.
    function testEndsWithIgnoresMemoryPastEnd() external pure {
        uint256[7] memory lengths = boundaryLengths();
        for (uint256 i = 0; i < lengths.length; i++) {
            for (uint256 j = 0; j < lengths.length; j++) {
                bytes memory tail = LibTestBytes.sequence(lengths[i], 1);
                bytes memory data =
                    LibTestBytes.trailedBy(bytes.concat(LibTestBytes.sequence(lengths[j], 0x60), tail), 0xFF);
                bytes memory suffix = LibTestBytes.trailedBy(tail, 0xEE);
                assertTrue(LibAffix.endsWith(data, suffix));
            }
        }
    }

    function testEndsWithMismatchEveryByte() external pure {
        uint256[7] memory lengths = boundaryLengths();
        for (uint256 i = 0; i < lengths.length; i++) {
            for (uint256 j = 0; j < lengths.length; j++) {
                bytes memory tail = LibTestBytes.sequence(lengths[i], 1);
                bytes memory data =
                    LibTestBytes.trailedBy(bytes.concat(LibTestBytes.sequence(lengths[j], 0x60), tail), 0xFF);
                bytes memory suffix = LibTestBytes.trailedBy(tail, 0xEE);
                for (uint256 k = 0; k < lengths[i]; k++) {
                    data[lengths[j] + k] ^= 0xFF;
                    assertFalse(LibAffix.endsWith(data, suffix));
                    data[lengths[j] + k] ^= 0xFF;
                    suffix[k] ^= 0xFF;
                    assertFalse(LibAffix.endsWith(data, suffix));
                    suffix[k] ^= 0xFF;
                }
                assertTrue(LibAffix.endsWith(data, suffix));
            }
        }
    }

    function testEndsWithAllocatesNothing(bytes memory data, bytes memory suffix) external pure {
        uint256 before;
        assembly ("memory-safe") {
            before := mload(0x40)
        }
        LibAffix.endsWith(data, suffix);
        uint256 afterCall;
        assembly ("memory-safe") {
            afterCall := mload(0x40)
        }
        assertEq(afterCall, before);
    }

    function testEndsWithStringReference(string memory data, string memory suffix) external pure {
        assertEq(LibAffix.endsWith(data, suffix), LibAffixSlow.endsWithSlow(bytes(data), bytes(suffix)));
    }

    function testEndsWithStringOwnSuffix(string memory data, uint256 length) external pure {
        length = bound(length, 0, bytes(data).length);
        string memory suffix = string(LibTestBytes.slice(bytes(data), bytes(data).length - length, bytes(data).length));
        assertTrue(LibAffix.endsWith(data, suffix));
    }

    function testEndsWithStringDirection() external pure {
        string memory data = "abcdef";
        string memory head = "abc";
        string memory tail = "def";
        assertTrue(LibAffix.endsWith(data, tail));
        assertFalse(LibAffix.endsWith(data, head));
        assertFalse(LibAffix.endsWith(tail, data));
    }
}
