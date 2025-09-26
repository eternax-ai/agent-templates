# EternaX Precompiles

This document describes the usage of EternaX's precompiles for creating autonomous AI agents with scheduling capabilities.

## Overview

EternaX provides two powerful precompiles that work together to enable autonomous AI agent behavior:

1. **Neural Routing Precompile** - Handles AI inference requests with callbacks
2. **Scheduling Precompile** - Manages deferred and recurring transaction execution

When combined, these precompiles enable the creation of "agent loops" where AI models can:
- Process inputs and make decisions
- Schedule future actions based on those decisions
- Create recurring behaviors and autonomous workflows
- Build complex multi-step agent behaviors

## Neural Routing Precompile

**Address**: `0x0000000000000000000000000000000000000403`

The Neural Routing precompile enables smart contracts to request AI inference from neural nodes with callback functionality.

### `requestInference`

Requests an AI inference with automatic callback execution and optional structured output schema.

```solidity
function requestInference(
    bytes memory inputData,
    string memory modelName,
    bool requiresTee,
    bytes memory outputSchema,
    address callbackContract,
    uint32 functionSelector,
    bytes memory callbackData,
    uint256 callbackGasLimit
) external returns (bytes32 requestId);
```

**Parameters:**
- `inputData`: The input data for the AI model (cannot be empty)
- `modelName`: Name of the AI model to use (cannot be empty) 
- `requiresTee`: Whether the inference requires Trusted Execution Environment
- `outputSchema`: JSON schema for structured output (empty bytes for no schema)
- `callbackContract`: Address of the contract to call back
- `functionSelector`: 4-byte function selector for the callback
- `callbackData`: Additional data to pass to the callback
- `callbackGasLimit`: Gas limit for the callback execution (1-1,000,000)

**Returns:**
- `requestId`: Unique identifier for the inference request

### Structured Output Schemas

The `outputSchema` parameter allows you to specify a JSON schema that defines the expected structure of the AI model's response (see [Schema-Based Callback](./SCHEMA_CALLBACK.md) for more details). This ensures:

- **Consistent data format**: Responses follow a predictable structure
- **Type validation**: Automatic validation of response data types
- **Required fields**: Ensures all necessary fields are present
- **Value constraints**: Enforces ranges, enums, and other constraints

## Scheduling Precompile

**Address**: `0x0000000000000000000000000000000000000402`

The Scheduling precompile enables smart contracts to schedule future transaction execution, both one-time and recurring.

### `scheduleCall`

Schedules a single transaction for future execution.

```solidity
function scheduleCall(
    uint256 targetBlock,
    address target,
    uint256 value,
    bytes memory data,
    uint64 gasLimit,
    uint256 nonce
) external returns (uint32 transactionId);
```

**Parameters:**
- `targetBlock`: Block number when the transaction should execute
- `target`: Address of the contract to call
- `value`: ETX value to send with the call
- `data`: Call data for the transaction (max 1024 bytes)
- `gasLimit`: Gas limit for the scheduled transaction
- `nonce`: Transaction nonce (0 = auto-assign)

**Returns:**
- `transactionId`: Unique identifier for the scheduled transaction

### `scheduleRecurringCall`

Schedules a recurring transaction for repeated execution.

```solidity
function scheduleRecurringCall(
    uint256 targetBlock,
    address target,
    uint256 value,
    bytes memory data,
    uint64 gasLimit,
    uint256 nonce,
    uint32 interval,
    uint32 maxExecutions
) external returns (uint32 transactionId);
```

**Parameters:**
- `targetBlock`: Block number for the first execution
- `target`: Address of the contract to call
- `value`: ETX value to send with each call
- `data`: Call data for the transaction (max 1024 bytes)
- `gasLimit`: Gas limit for each scheduled transaction
- `nonce`: Transaction nonce (0 = auto-assign)
- `interval`: Blocks between executions
- `maxExecutions`: Maximum number of executions (0 = unlimited)

**Returns:**
- `transactionId`: Unique identifier for the recurring transaction

### `cancelCall`

Cancels a previously scheduled transaction.

```solidity
function cancelCall(
    uint256 targetBlock,
    uint32 transactionId
) external returns (bool success);
```

## Conclusion

EternaX precompiles enable the creation of sophisticated autonomous agents that can:
- Process information using AI models
- Make decisions based on current state
- Schedule future actions and recurring behaviors
- Coordinate with other agents
- Respond to environmental changes

The combination of neural routing and scheduling creates a powerful foundation for building the next generation of blockchain applications.