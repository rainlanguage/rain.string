// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.2/src/Test.sol";

import {LibAffix} from "../../../../src/lib/affix/LibAffix.sol";
import {LibAffixSlow} from "../../../lib/affix/LibAffixSlow.sol";
import {LibTestBytes} from "../../../lib/LibTestBytes.sol";

contract LibAffixStartsWithTest is Test {
    function boundaryLengths() internal pure returns (uint256[7] memory) {
        return [uint256(0), 1, 31, 32, 33, 64, 65];
    }

    function testStartsWithReference(bytes memory data, bytes memory prefix) external pure {
        assertEq(LibAffix.startsWith(data, prefix), LibAffixSlow.startsWithSlow(data, prefix));
    }

    function testStartsWithOwnPrefix(bytes memory data, uint256 length) external pure {
        length = bound(length, 0, data.length);
        bytes memory prefix = LibTestBytes.trailedBy(LibTestBytes.slice(data, 0, length), 0xEE);
        assertTrue(LibAffixSlow.startsWithSlow(data, prefix));
        assertTrue(LibAffix.startsWith(data, prefix));
    }

    function testStartsWithCorruptedPrefix(bytes memory data, uint256 length, uint256 index, uint8 mask) external pure {
        vm.assume(data.length > 0);
        vm.assume(mask != 0);
        length = bound(length, 1, data.length);
        index = bound(index, 0, length - 1);
        bytes memory prefix = LibTestBytes.slice(data, 0, length);
        prefix[index] ^= bytes1(mask);
        assertFalse(LibAffixSlow.startsWithSlow(data, prefix));
        assertFalse(LibAffix.startsWith(data, prefix));
    }

    function testStartsWithEmptyPrefix(bytes memory data) external pure {
        assertTrue(LibAffix.startsWith(data, ""));
    }

    function testStartsWithEmptyData(bytes memory prefix) external pure {
        assertEq(LibAffix.startsWith("", prefix), prefix.length == 0);
    }

    function testStartsWithWholeData(bytes memory data) external pure {
        assertTrue(LibAffix.startsWith(data, bytes.concat(data)));
    }

    /// The memory past `data` holds the rest of `prefix`, so only the length
    /// check rejects it.
    function testStartsWithLongerPrefix(bytes memory prefix, uint256 length) external pure {
        vm.assume(prefix.length > 0);
        length = bound(length, 0, prefix.length - 1);
        bytes memory data = LibTestBytes.truncated(prefix, length);
        assertFalse(LibAffixSlow.startsWithSlow(data, prefix));
        assertFalse(LibAffix.startsWith(data, prefix));
    }

    function testStartsWithLongerByOne() external pure {
        uint256[7] memory lengths = boundaryLengths();
        for (uint256 i = 0; i < lengths.length; i++) {
            bytes memory prefix = LibTestBytes.sequence(lengths[i] + 1, 1);
            assertFalse(LibAffix.startsWith(LibTestBytes.truncated(prefix, lengths[i]), prefix));
        }
    }

    /// Different non-zero fills follow `data` and `prefix`, so any read past
    /// either length changes the result.
    function testStartsWithIgnoresMemoryPastEnd() external pure {
        uint256[7] memory lengths = boundaryLengths();
        for (uint256 i = 0; i < lengths.length; i++) {
            for (uint256 j = 0; j < lengths.length; j++) {
                bytes memory head = LibTestBytes.sequence(lengths[i], 1);
                bytes memory data =
                    LibTestBytes.trailedBy(bytes.concat(head, LibTestBytes.sequence(lengths[j], 0x60)), 0xFF);
                bytes memory prefix = LibTestBytes.trailedBy(head, 0xEE);
                assertTrue(LibAffix.startsWith(data, prefix));
            }
        }
    }

    function testStartsWithMismatchEveryByte() external pure {
        uint256[7] memory lengths = boundaryLengths();
        for (uint256 i = 0; i < lengths.length; i++) {
            for (uint256 j = 0; j < lengths.length; j++) {
                bytes memory head = LibTestBytes.sequence(lengths[i], 1);
                bytes memory data =
                    LibTestBytes.trailedBy(bytes.concat(head, LibTestBytes.sequence(lengths[j], 0x60)), 0xFF);
                bytes memory prefix = LibTestBytes.trailedBy(head, 0xEE);
                for (uint256 k = 0; k < lengths[i]; k++) {
                    data[k] ^= 0xFF;
                    assertFalse(LibAffix.startsWith(data, prefix));
                    data[k] ^= 0xFF;
                    prefix[k] ^= 0xFF;
                    assertFalse(LibAffix.startsWith(data, prefix));
                    prefix[k] ^= 0xFF;
                }
                assertTrue(LibAffix.startsWith(data, prefix));
            }
        }
    }

    function testStartsWithAllocatesNothing(bytes memory data, bytes memory prefix) external pure {
        uint256 before;
        assembly ("memory-safe") {
            before := mload(0x40)
        }
        LibAffix.startsWith(data, prefix);
        uint256 afterCall;
        assembly ("memory-safe") {
            afterCall := mload(0x40)
        }
        assertEq(afterCall, before);
    }

    function testStartsWithStringReference(string memory data, string memory prefix) external pure {
        assertEq(LibAffix.startsWith(data, prefix), LibAffixSlow.startsWithSlow(bytes(data), bytes(prefix)));
    }

    function testStartsWithStringOwnPrefix(string memory data, uint256 length) external pure {
        length = bound(length, 0, bytes(data).length);
        string memory prefix = string(LibTestBytes.slice(bytes(data), 0, length));
        assertTrue(LibAffix.startsWith(data, prefix));
    }

    function testStartsWithStringDirection() external pure {
        string memory data = "abcdef";
        string memory head = "abc";
        string memory tail = "def";
        assertTrue(LibAffix.startsWith(data, head));
        assertFalse(LibAffix.startsWith(data, tail));
        assertFalse(LibAffix.startsWith(head, data));
    }
}
