// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IScheduler {
    /// Schedule a call for future execution
    /// @param targetBlock The target block number for execution
    /// @param target The target contract address
    /// @param value The ETX value to send with the call
    /// @param data The call data (function selector + arguments)
    /// @param gasLimit The gas limit for the call
    /// @param nonce The nonce for the transaction (0 for auto-assignment)
    /// @return transactionId The ID of the scheduled transaction
    function scheduleCall(
        uint256 targetBlock,
        address target,
        uint256 value,
        bytes calldata data,
        uint64 gasLimit,
        uint256 nonce
    ) external returns (uint32 transactionId);

    /// Cancel a scheduled call
    /// @param targetBlock The target block number
    /// @param transactionId The transaction ID to cancel
    /// @return success Whether the cancellation was successful
    function cancelCall(
        uint256 targetBlock,
        uint32 transactionId
    ) external returns (bool success);

    /// Schedule a recurring call for future execution
    /// @param targetBlock The target block number for first execution
    /// @param target The target contract address
    /// @param value The ETX value to send with the call
    /// @param data The call data (function selector + arguments)
    /// @param gasLimit The gas limit for the call
    /// @param nonce The nonce for the transaction (0 for auto-assignment)
    /// @param interval The interval between executions (in blocks)
    /// @param maxExecutions The maximum number of executions (0 for unlimited)
    /// @return transactionId The ID of the scheduled transaction
    function scheduleRecurringCall(
        uint256 targetBlock,
        address target,
        uint256 value,
        bytes calldata data,
        uint64 gasLimit,
        uint256 nonce,
        uint32 interval,
        uint32 maxExecutions
    ) external returns (uint32 transactionId);
} 