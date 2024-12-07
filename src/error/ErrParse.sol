// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// The decimal string is empty.
/// @param position The position in the data where the error occurred.
error ParseEmptyDecimalString(uint256 position);

/// The decimal string is too large to fit in a `uint256`.
/// @param position The position in the data where the error occurred.
error ParseDecimalOverflow(uint256 position);
