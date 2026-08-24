// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// The decimal string is empty.
/// `LibParseDecimal` never abi-encodes a position; it returns this error's
/// bare 4-byte selector to its caller instead of reverting. The `position`
/// parameter is the contract for downstream reverters: a caller that reverts
/// with this error appends the position it tracks itself. The selector's
/// keccak preimage is the full `ParseEmptyDecimalString(uint256)` signature,
/// so the parameter cannot be removed without changing the selector.
/// @param position The position in the data where the error occurred.
/// Supplied by the reverting caller, not by `LibParseDecimal`.
error ParseEmptyDecimalString(uint256 position);

/// The decimal string is too large to fit in a `uint256`.
/// `LibParseDecimal` never abi-encodes a position; it returns this error's
/// bare 4-byte selector to its caller instead of reverting. The `position`
/// parameter is the contract for downstream reverters: a caller that reverts
/// with this error appends the position it tracks itself. The selector's
/// keccak preimage is the full `ParseDecimalOverflow(uint256)` signature,
/// so the parameter cannot be removed without changing the selector.
/// @param position The position in the data where the error occurred.
/// Supplied by the reverting caller, not by `LibParseDecimal`.
error ParseDecimalOverflow(uint256 position);

/// The decimal string start pointer is zero.
error ZeroStringStartPointer();
