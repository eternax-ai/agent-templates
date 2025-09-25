// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface INeuralRouting {
    function requestInference(
        bytes memory inputData,
        string memory modelName,
        bool requiresTee,
        bytes memory outputSchema, // Empty bytes array represents no schema (None in Rust)
        address callbackContract,
        uint32 functionSelector,
        bytes memory callbackData,
        uint256 callbackGasLimit
    ) external returns (bytes32 requestId);
} 