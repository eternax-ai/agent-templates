# eternaX Network Agent Development Guide

## Overview

This guide provides a comprehensive template and examples for creating AI-powered autonomous agents on the eternaX Network. The template system is designed based on analysis of successful agents like Counter, AIAsker, and BettingAgent.

## Architecture Components

### 1. BaseAgent Contract

The `BaseAgent.sol` provides:
- Common infrastructure for AI inference and scheduling
- Owner management and access control
- Request tracking and state management
- Error handling patterns
- Extensible callback system
- Configurable AI schemas and models

### 2. Key Interfaces

- **INeuralRouting (0x403)**: AI model inference with structured output
- **IScheduler (0x402)**: Automated periodic execution
- **IMarketOracle** , **IPredictionMarket**: Market integration
- **IWETX**: WETX token integration

### 3. Common Patterns

All successful agents share these patterns:
- Owner-based access control
- Automated scheduling for periodic execution
- State tracking (requests sent/received)
- Comprehensive error handling with events
- JSON schema-based AI responses
- Callback mechanisms for AI responses

## Getting Started

### Step 1: Inherit from BaseAgent

```solidity
contract MyAgent is BaseAgent {
    constructor(uint256 _executionInterval, uint32 _maxExecutions) 
        BaseAgent(_executionInterval, _maxExecutions) 
    {
        // Your initialization
    }
}
```

### Step 2: Implement Abstract Functions

You must implement these four abstract functions:

#### 2.1 executeAgentLogic()
```solidity
function executeAgentLogic() external override onlySelf whenActive returns (bool success) {
    // Your main business logic here
    // This gets called by the scheduler
    // Return true for success, false for failure
}
```

#### 2.2 getInferenceConfig()
```solidity
function getInferenceConfig(string memory context) internal override returns (InferenceConfig memory config) {
    // Configure AI model and schema based on context
    // Different contexts can use different models/schemas
}
```

#### 2.3 processAIResponse()
```solidity
function processAIResponse(bytes32 requestId, string memory response) internal override {
    // Handle structured AI responses
    // Parse JSON and execute business logic
}
```

**Important Note on Structured AI Responses:**

For agents that need structured AI responses with JSON schema parsing, you have two options:

**Option 1: Simple String Responses (Default)**
- Use BaseAgent's `requestAIInference()` method
- Override `processAIResponse()` to handle raw string responses
- Good for simple text-based AI interactions

**Option 2: Structured Responses with JSON Schema**
- Call `neuralRouting.requestInference()` directly (bypass BaseAgent)
- Use custom callback functions with parsed parameters
- Required for complex structured data

Example of structured callback:
```solidity
function processStructuredAIResponse(bytes32 requestId, string memory bet, uint256 confidence, string memory reason) external {
    require(msg.sender == NEURAL_ROUTING, "Only Neural Routing precompile can provide responses");
    
    // Validate structured response
    require(confidence <= 100, "Confidence must be <= 100");
    
    // Use parsed parameters directly
    if (keccak256(abi.encodePacked(bet)) == keccak256(abi.encodePacked("yes"))) {
        // Handle "yes" prediction with confidence level
    }
}
```

**JSON Schema Example:**
```solidity
string memory jsonSchema = '{"type":"object","properties":{"bet":{"type":"string","enum":["yes","no"]},"confidence":{"type":"integer","minimum":0,"maximum":100},"reason":{"type":"string"}},"required":["bet","confidence","reason"]}';
```

#### 2.4 validateConfiguration()
```solidity
function validateConfiguration() internal override view returns (bool isValid) {
    // Validate your agent's configuration
    // Return false to prevent activation with invalid config
}
```

### Step 3: Define Your Business Logic

Add your specific state variables, events, and functions:

```solidity
contract MyBettingAgent is BaseAgent {
    // Your state
    struct BetPosition {
        bytes32 marketId;
        bool isActive;
        uint256 amount;
        bool prediction;
        // ... other fields
    }
    
    BetPosition public currentPosition;
    
    // Your events
    event BetPlaced(bytes32 indexed marketId, bool prediction, uint256 amount);
    
    // Your business functions
    function placeBet(bytes32 marketId, bool prediction, uint256 amount) internal {
        // Your betting logic
        emit BetPlaced(marketId, prediction, amount);
    }
}
```

## Configuration Examples

### Basic Agent Configuration

```solidity
// Every 10 blocks, maximum 100 executions
MyAgent agent = new MyAgent(10, 100);

// Activate the agent
agent.setActive(true);

// Setup periodic execution
uint32 scheduleId = agent.setupPeriodicExecution();
```

### AI Schema Examples

#### Market Prediction Schema
```json
{
  "type": "object",
  "properties": {
    "prediction": {"type": "string", "enum": ["yes", "no"]},
    "confidence": {"type": "integer", "minimum": 0, "maximum": 100},
    "reasoning": {"type": "string"},
    "recommended_bet_size": {"type": "string", "enum": ["small", "medium", "large", "none"]}
  },
  "required": ["prediction", "confidence", "reasoning", "recommended_bet_size"]
}
```

#### Risk Assessment Schema
```json
{
  "type": "object",
  "properties": {
    "risk_level": {"type": "integer", "minimum": 1, "maximum": 10},
    "factors": {"type": "array", "items": {"type": "string"}},
    "recommendation": {"type": "string", "enum": ["reduce", "maintain", "increase"]},
    "max_exposure": {"type": "number"}
  },
  "required": ["risk_level", "recommendation"]
}
```

#### General Analysis Schema
```json
{
  "type": "object",
  "properties": {
    "analysis": {"type": "string"},
    "key_points": {"type": "array", "items": {"type": "string"}},
    "confidence": {"type": "integer", "minimum": 0, "maximum": 100},
    "actionable_insights": {"type": "array", "items": {"type": "string"}}
  },
  "required": ["analysis", "confidence"]
}
```

## Best Practices

### 1. Error Handling

Always use try-catch blocks for external calls:

```solidity
try this.requestAIInference(inputData, context) returns (bytes32 requestId) {
    // Success logic
    return true;
} catch Error(string memory reason) {
    // Handle specific error
    emit ErrorOccurred(reason);
    return false;
} catch {
    // Handle general error
    emit ErrorOccurred("Unknown error");
    return false;
}
```

### 2. Gas Management

- Set appropriate gas limits for callbacks (150k-300k typical)
- Consider gas costs in your business logic
- Use gas-efficient data structures

### 3. State Management

- Track all important state changes with events
- Implement proper state validation
- Use mappings for efficient lookups

### 4. Security

- Always validate AI responses before acting on them
- Use proper access control modifiers
- Implement emergency pause functionality
- Validate external data sources

### 5. Schema Design

- Make schemas specific enough to get structured data
- Include validation constraints (min/max, enums)
- Design for your specific use case
- Test schemas with your target AI models

## Example Implementations

### 1. ExampleAgent.sol
A simple agent that demonstrates:
- Multiple question types with different schemas
- Response processing for different contexts
- Basic state management

### 2. SimpleBettingAgent.sol
A more advanced example showing:
- Prediction market integration with oracles
- Risk management and bet sizing
- Native ETX token handling for deposits and withdrawals
- Complex business logic with multiple analysis types
- Automated betting based on AI predictions

## Deployment and Testing

### 1. Local Testing

```javascript
// Deploy your agent
const MyAgent = await ethers.getContractFactory("MyAgent");
const agent = await MyAgent.deploy(10, 100); // 10 block interval, 100 max executions

// For betting agents, you also need:
// const bettingAgent = await BettingAgent.deploy(10, 100, oracleAddress, marketAddress);

// Activate
await agent.setActive(true);

// Test manual execution
await agent.manualExecution();

// Setup periodic execution
await agent.setupPeriodicExecution();
```

### 2. Monitoring

Monitor these events:
- `InferenceRequested`: Track AI requests
- `InferenceResponseReceived`: Track AI responses
- `AgentExecutionCompleted`: Track successful executions
- `AgentExecutionFailed`: Track failures

### 3. Debugging

Use the provided state functions:
```solidity
// Get current state
(uint256 sent, uint256 received, uint256 lastRequest, bool requesting, bool active) = agent.getState();

// Get request info
RequestInfo memory info = agent.getRequestInfo(requestId);
```

## Common Patterns

### 1. Context-Based Schema Selection

```solidity
function getInferenceConfig(string memory context) internal pure override returns (InferenceConfig memory config) {
    bytes32 contextHash = keccak256(abi.encodePacked(context));
    
    if (contextHash == keccak256(abi.encodePacked("trading"))) {
        config.jsonSchema = TRADING_SCHEMA;
    } else if (contextHash == keccak256(abi.encodePacked("risk"))) {
        config.jsonSchema = RISK_SCHEMA;
    }
    // ... other contexts
}
```

### 2. Progressive Decision Making

```solidity
function executeAgentLogic() external override onlySelf whenActive returns (bool) {
    if (needsMarketAnalysis()) {
        return requestMarketAnalysis();
    } else if (needsRiskAssessment()) {
        return requestRiskAssessment();
    } else if (needsExecution()) {
        return executeAction();
    }
    return true; // No action needed
}
```

### 3. Response Validation

```solidity
function processAIResponse(bytes32 requestId, string memory response) internal override {
    // Always validate responses before acting
    if (!isValidResponse(response)) {
        emit InvalidResponse(requestId, response);
        return;
    }
    
    // Parse and execute
    ActionData memory action = parseResponse(response);
    if (action.confidence >= minimumConfidence) {
        executeAction(action);
    }
}
```

## Advanced Features

### 1. Multi-Model Agents

Use different AI models for different tasks:
- Small models for simple decisions
- Large models for complex analysis
- Specialized models for domain-specific tasks

### 2. Adaptive Schemas

Modify schemas based on agent performance:
```solidity
function adaptSchema(uint256 successRate) internal {
    if (successRate < 60) {
        // Use more restrictive schema
        currentSchema = CONSERVATIVE_SCHEMA;
    } else if (successRate > 80) {
        // Use more flexible schema
        currentSchema = AGGRESSIVE_SCHEMA;
    }
}
```

### 3. Cross-Agent Communication

Agents can interact with each other:
```solidity
function consultOtherAgent(address otherAgent, bytes memory question) external {
    IOtherAgent(otherAgent).requestConsultation(question);
}
```

## Troubleshooting

### Common Issues

1. **Schema Validation Failures**
   - Check JSON schema syntax
   - Ensure required fields are present
   - Verify enum values match expected outputs

2. **Callback Not Executing**
   - Verify function selector is correct
   - Check gas limit is sufficient
   - Ensure callback function is public/external

3. **Agent Not Executing**
   - Verify agent is active
   - Check scheduler setup
   - Monitor for execution failures

4. **High Gas Costs**
   - Optimize callback gas limits
   - Reduce schema complexity
   - Batch operations where possible

### Getting Help

1. Check event logs for detailed error information
2. Use the provided debugging functions
3. Test with manual execution before scheduling
4. Monitor gas usage and optimize accordingly

## Conclusion

The BaseAgent template provides a robust foundation for building AI-powered autonomous agents on eternaX Network. By following this guide and using the provided examples, you can create sophisticated agents that leverage AI inference while maintaining security and efficiency.

Remember:
- **Schemas should be configurable, not constructor parameters**
- **Always validate AI responses before acting**
- **Implement comprehensive error handling**
- **Monitor and optimize gas usage**
- **Test thoroughly before deployment**

For more examples and updates, refer to the contract implementations in this repository.