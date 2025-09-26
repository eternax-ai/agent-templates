// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./interfaces/INeuralRouting.sol";
import "./interfaces/IScheduler.sol";

/**
 * @title BaseAgent
 * @dev Abstract base contract for creating AI-powered autonomous agents on blockchain.
 * 
 * This template provides:
 * - Common infrastructure for AI inference and scheduling
 * - Owner management and access control
 * - Request tracking and state management
 * - Error handling patterns
 * - Extensible callback system
 * - Configurable AI schemas and models
 * 
 * Key Features:
 * - Automated periodic execution via Scheduler precompile
 * - Structured AI inference via Neural Routing precompile
 * - Flexible schema management (not constructor-bound)
 * - Comprehensive event logging for monitoring
 * - Gas-efficient execution patterns
 * - Security best practices
 * 
 * To create your own agent:
 * 1. Inherit from BaseAgent
 * 2. Implement the abstract functions
 * 3. Define your business logic in executeAgentLogic()
 * 4. Configure your AI schemas in getInferenceConfig()
 * 5. Handle AI responses in processAIResponse()
 * 
 * @author Template for eternaX Network Agent Development
 * @notice This is a base template - inherit and implement abstract functions
 * @dev Uses Neural Routing (0x403) and Scheduler (0x402) precompiles
 */
abstract contract BaseAgent {
    // Precompile addresses (constants across all agents)
    address public constant NEURAL_ROUTING = 0x0000000000000000000000000000000000000403;
    address public constant SCHEDULER = 0x0000000000000000000000000000000000000402;
    
    // Core state variables
    address public owner;
    
    // Interface instances
    INeuralRouting internal neuralRouting;
    IScheduler internal scheduler;
    
    // Request tracking
    uint256 public inferenceRequestsSent;
    uint256 public inferenceResponsesReceived;
    uint256 public lastInferenceRequest;
    bool public isRequestingInference;
    
    // Agent configuration
    bool public isActive;
    uint256 public executionInterval; // blocks between executions
    uint32 public maxExecutions; // maximum scheduled executions
    
    // Request mapping for tracking
    mapping(bytes32 => RequestInfo) internal requests;
    
    struct RequestInfo {
        uint256 timestamp;
        string context;
        bool processed;
    }
    
    struct InferenceConfig {
        string modelName;
        bool requiresTee;
        string jsonSchema;
        uint256 callbackGasLimit;
        uint32 functionSelector;
    }
    
    // Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AgentActivated(bool active);
    event InferenceRequested(bytes32 indexed requestId, string context);
    event InferenceResponseReceived(bytes32 indexed requestId, string response);
    event InferenceRequestFailed(string reason);
    event AgentExecutionCompleted(uint256 timestamp, bool success);
    event AgentExecutionFailed(string reason);
    event ConfigurationUpdated(uint256 interval, uint32 maxExecutions);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "BaseAgent: Only owner can call this function");
        _;
    }
    
    modifier onlySelf() {
        require(msg.sender == address(this), "BaseAgent: Only self-execution allowed");
        _;
    }
    
    modifier onlyNeuralRouting() {
        require(msg.sender == NEURAL_ROUTING, "BaseAgent: Only Neural Routing can call this");
        _;
    }
    
    modifier whenActive() {
        require(isActive, "BaseAgent: Agent is not active");
        _;
    }
    
    /**
     * @dev Constructor initializes the base agent with owner and interfaces
     * @param _executionInterval Blocks between automated executions
     * @param _maxExecutions Maximum number of scheduled executions (0 for unlimited)
     */
    constructor(uint256 _executionInterval, uint32 _maxExecutions) {
        owner = msg.sender;
        neuralRouting = INeuralRouting(NEURAL_ROUTING);
        scheduler = IScheduler(SCHEDULER);
        
        executionInterval = _executionInterval;
        maxExecutions = _maxExecutions;
        isActive = false;
        
        inferenceRequestsSent = 0;
        inferenceResponsesReceived = 0;
        lastInferenceRequest = 0;
        isRequestingInference = false;
    }
    
    // =============================================================================
    // ABSTRACT FUNCTIONS - MUST BE IMPLEMENTED BY CHILD CONTRACTS
    // =============================================================================
    
    /**
     * @dev Main business logic for the agent - called by scheduler
     * @return success Whether the execution was successful
     * @notice Implement your agent's core functionality here
     */
    function executeAgentLogic() external virtual returns (bool success);
    
    /**
     * @dev Configure AI inference parameters for requests
     * @param context The context or reason for the inference request
     * @return config The inference configuration including model, schema, etc.
     * @notice Return different configs based on context if needed
     */
    function getInferenceConfig(string memory context) internal virtual returns (InferenceConfig memory config);
    
    /**
     * @dev Process structured AI response from Neural Routing callback
     * @param requestId The unique identifier for the inference request
     * @param response The structured response from AI (parsed according to schema)
     * @notice Implement your response handling logic here
     */
    function processAIResponse(bytes32 requestId, string memory response) internal virtual;
    
    /**
     * @dev Validate agent configuration before activation
     * @return isValid Whether the current configuration is valid
     * @notice Override to add custom validation logic
     */
    function validateConfiguration() internal virtual view returns (bool isValid);
    
    // =============================================================================
    // CORE FUNCTIONALITY - PROVIDED BY BASE CONTRACT
    // =============================================================================
    
    /**
     * @dev Transfer ownership of the agent to a new account
     * @param newOwner The address to transfer ownership to
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "BaseAgent: New owner cannot be zero address");
        
        address oldOwner = owner;
        owner = newOwner;
        
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    /**
     * @dev Activate or deactivate the agent
     * @param _active Whether the agent should be active
     */
    function setActive(bool _active) external onlyOwner {
        if (_active) {
            require(validateConfiguration(), "BaseAgent: Invalid configuration");
        }
        
        isActive = _active;
        emit AgentActivated(_active);
    }
    
    /**
     * @dev Update agent execution configuration
     * @param _executionInterval New interval between executions
     * @param _maxExecutions New maximum number of executions
     */
    function updateConfiguration(uint256 _executionInterval, uint32 _maxExecutions) external onlyOwner {
        require(_executionInterval > 0, "BaseAgent: Execution interval must be positive");
        
        executionInterval = _executionInterval;
        maxExecutions = _maxExecutions;
        
        emit ConfigurationUpdated(_executionInterval, _maxExecutions);
    }
    
    /**
     * @dev Setup periodic execution using the Scheduler precompile
     * @return transactionId The ID of the scheduled transaction
     */
    function setupPeriodicExecution() external onlyOwner whenActive returns (uint32) {
        require(executionInterval > 0, "BaseAgent: Execution interval not set");
        
        // Start in 'executionInterval' blocks
        uint256 targetBlock = block.number + 10;
        
        // Schedule the recurring execution
        try scheduler.scheduleRecurringCall(
            targetBlock,
            address(this),
            0, // no ETX value
            abi.encodeWithSignature("executeAgentLogic()"),
            1000000, // gas limit
            0, // auto-assign nonce
            uint32(executionInterval),
            maxExecutions
        ) returns (uint32 transactionId) {
            return transactionId;
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("BaseAgent: Failed to schedule execution: ", reason)));
        }
    }
    
    /**
     * @dev Make an AI inference request with configurable schema
     * @param inputData The input data for the AI model
     * @param context Context string for tracking and configuration
     * @return requestId The unique identifier for the request
     */
    function requestAIInference(bytes memory inputData, string memory context) internal returns (bytes32) {
        require(!isRequestingInference, "BaseAgent: Already requesting inference");
        
        isRequestingInference = true;
        lastInferenceRequest = block.timestamp;
        
        // Get inference configuration based on context
        InferenceConfig memory config = getInferenceConfig(context);
        
        // Convert JSON schema to bytes
        bytes memory outputSchema = bytes(config.jsonSchema);
        
        try neuralRouting.requestInference(
            inputData,
            config.modelName,
            config.requiresTee,
            outputSchema,
            address(this),
            config.functionSelector,
            "",
            config.callbackGasLimit
        ) returns (bytes32 requestId) {
            // Store request info
            requests[requestId] = RequestInfo({
                timestamp: block.timestamp,
                context: context,
                processed: false
            });
            
            inferenceRequestsSent++;
            isRequestingInference = false;
            
            emit InferenceRequested(requestId, context);
            return requestId;
        } catch Error(string memory reason) {
            isRequestingInference = false;
            // Return bytes32(0) to indicate failure instead of reverting
            emit InferenceRequestFailed(reason);
            return bytes32(0);
        } catch (bytes memory) {
            isRequestingInference = false;
            // Return bytes32(0) to indicate failure instead of reverting
            emit InferenceRequestFailed("Unknown error");
            return bytes32(0);
        }
    }
    
    /**
     * @dev Default callback function for AI responses
     * @param requestId The unique identifier for the inference request
     * @param response The response from the AI model
     * @notice This is called by Neural Routing - override processAIResponse for custom logic
     * 
     * IMPORTANT: For structured AI responses with JSON schema parsing, you need to:
     * 1. Call neuralRouting.requestInference() directly instead of requestAIInference()
     * 2. Use a custom callback function (e.g., processStructuredAIResponse) with parsed parameters
     * 3. Set the function selector in the requestInference call to your custom callback
     * 
     * This handleAICallback only provides raw string responses, not structured/parsed data.
     */
    function handleAICallback(bytes32 requestId, string memory response) external onlyNeuralRouting {
        require(!requests[requestId].processed, "BaseAgent: Request already processed");
        
        requests[requestId].processed = true;
        inferenceResponsesReceived++;
        
        emit InferenceResponseReceived(requestId, response);
        
        // Call the abstract function for child contracts to handle
        processAIResponse(requestId, response);
    }
    
    /**
     * @dev Manual execution trigger for testing
     * @return success Whether the execution was successful
     */
    function manualExecution() external onlyOwner returns (bool) {
        try this.executeAgentLogic() returns (bool success) {
            emit AgentExecutionCompleted(block.timestamp, success);
            return success;
        } catch Error(string memory reason) {
            emit AgentExecutionFailed(reason);
            return false;
        }
    }
    
    /**
     * @dev Get current agent state
     * @return _inferenceRequestsSent Total inference requests sent
     * @return _inferenceResponsesReceived Total responses received
     * @return _lastInferenceRequest Timestamp of last request
     * @return _isRequestingInference Whether currently requesting
     * @return _isActive Whether agent is active
     */
    function getState() external view returns (
        uint256 _inferenceRequestsSent,
        uint256 _inferenceResponsesReceived,
        uint256 _lastInferenceRequest,
        bool _isRequestingInference,
        bool _isActive
    ) {
        return (
            inferenceRequestsSent,
            inferenceResponsesReceived,
            lastInferenceRequest,
            isRequestingInference,
            isActive
        );
    }
    
    /**
     * @dev Get information about a specific request
     * @param requestId The request ID to query
     * @return info The request information
     */
    function getRequestInfo(bytes32 requestId) external view returns (RequestInfo memory info) {
        return requests[requestId];
    }
    
    /**
     * @dev Utility function to convert uint256 to string
     * @param value The uint256 value to convert
     * @return The string representation
     */
    function _uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    /**
     * @dev Emergency pause function
     */
    function emergencyPause() external onlyOwner {
        isActive = false;
        emit AgentActivated(false);
    }
    
    /**
     * @dev Fallback function
     */
    fallback() external {
        // Clean fallback
    }
    
    /**
     * @dev Receive function for ETX
     */
    receive() external virtual payable {
        // Allow receiving ETX
    }
}