# AI Agent Template for eternaX Network

## Quick Start

This template provides everything you need to create AI-powered autonomous agents on eternaX Network.

### 1-Minute Setup

```bash
# Clone and install
npm install

# Deploy example agents
npm run deploy

# Your agents are now running autonomously!
```

## Template Structure

```
contracts/
├── BaseAgent.sol           # Core template - inherit from this
├── Payer.sol               # Scheduling and payment example
├── SimpleBettingAgent.sol  # Advanced example (betting logic)
└── interfaces/             # Required interfaces

scripts/
└── deploy-example-agent.js # Deployment script

docs/
└── AGENT_DEVELOPMENT_GUIDE.md  # Complete guide
```

## How to Create Your Agent

### Step 1: Inherit from BaseAgent

```solidity
import "./BaseAgent.sol";

contract MyAgent is BaseAgent {
    constructor(uint256 interval, uint32 maxExecutions) 
        BaseAgent(interval, maxExecutions) 
    {
        // Your initialization
    }
}
```

### Step 2: Implement 4 Required Functions

```solidity
// 1. Your main business logic
function executeAgentLogic() external override onlySelf whenActive returns (bool) {
    // Called by scheduler - implement your logic here
}

// 2. Configure AI models & schemas per request
function getInferenceConfig(string memory context) internal override returns (InferenceConfig memory) {
    // Return different configs based on context
}

// 3. Handle AI responses
function processAIResponse(bytes32 requestId, string memory response) internal override {
    // Parse JSON response and execute actions
}

// 4. Validate your configuration
function validateConfiguration() internal override view returns (bool) {
    // Return true if agent is properly configured
}
```

### Step 3: Deploy & Activate

```javascript
const agent = await MyAgent.deploy(10, 100); // 10 blocks interval, 100 max executions
await agent.setActive(true);
await agent.setupPeriodicExecution();
```

## Schema Examples

### Market Prediction
```json
{
  "type": "object",
  "properties": {
    "prediction": {"type": "string", "enum": ["buy", "sell", "hold"]},
    "confidence": {"type": "integer", "minimum": 0, "maximum": 100},
    "reasoning": {"type": "string"}
  },
  "required": ["prediction", "confidence", "reasoning"]
}
```

### Risk Assessment
```json
{
  "type": "object",
  "properties": {
    "risk_level": {"type": "integer", "minimum": 1, "maximum": 10},
    "recommendation": {"type": "string", "enum": ["reduce", "maintain", "increase"]},
    "factors": {"type": "array", "items": {"type": "string"}}
  },
  "required": ["risk_level", "recommendation"]
}
```

## Flexible Schema Configuration

### Dynamic Schema Evolution
```solidity
function adaptSchema(uint256 successRate) internal {
    if (successRate < 60) {
        currentSchema = CONSERVATIVE_SCHEMA; // More restrictive
    } else if (successRate > 80) {
        currentSchema = AGGRESSIVE_SCHEMA;   // More flexible
    }
}
```

## Best Practices

### DO
- Always validate AI responses before acting
- Use try-catch for all external calls
- Implement emergency pause functionality
- Monitor gas usage and optimize
- Test schemas with your target AI models

### DON'T
- Put schemas in constructor parameters
- Act on unvalidated AI responses
- Ignore error handling
- Deploy without testing
- Use overly complex schemas

## Monitoring Your Agent

### Events to Watch
```solidity
event InferenceRequested(bytes32 indexed requestId, string context);
event InferenceResponseReceived(bytes32 indexed requestId, string response);
event AgentExecutionCompleted(uint256 timestamp, bool success);
event AgentExecutionFailed(string reason);
```

### State Functions
```solidity
// Get overall state
(uint256 sent, uint256 received, uint256 lastRequest, bool requesting, bool active) = agent.getState();

// Get specific request info
RequestInfo memory info = agent.getRequestInfo(requestId);
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Agent not executing | Check if active and scheduled |
| Callback not working | Verify function selector and gas limit |
| Schema validation fails | Check JSON syntax and required fields |
| High gas costs | Optimize callback gas limits and schema complexity |

## Examples Included

### 1. ExampleAgent
- **Purpose**: Demonstrates basic agent functionality
- **Features**: Rotates through different question types
- **Schemas**: Market prediction, general analysis, sentiment
- **Good for**: Learning the template basics

### 2. SimpleBettingAgent
- **Purpose**: Shows advanced betting agent for prediction markets
- **Features**: Risk management, bet sizing, native ETX handling, multiple models
- **Schemas**: Market analysis, risk assessment, portfolio review
- **Good for**: Understanding complex agent logic with real market integration

## Ready to Build?

1. **Read**: `AGENT_DEVELOPMENT_GUIDE.md` for complete details
2. **Study**: `SimpleBettingAgent.sol`
3. **Inherit**: From `BaseAgent.sol`
4. **Implement**: The 4 required functions
5. **Deploy**: Using the provided script
6. **Monitor**: Using events and state functions

## Testnet Configuration

- **EternaX testnet1** is configured in hardhat.config.js with a few pre-funded accounts. Please use with moderation.
- The RPC URL is `https://rpc.eternax.ai`
- The model available for inference is `llama3.1:8b-instruct-q8_0`
- The Market Oracle is deployed at `0x4D589B49d8763C9FaaE726d464E3B9F53347BED4`
- The Prediction Market is deployed at `0xB27B171a18B589E086D2f11148D3F0C8f1f8032c`
- The WETX token is deployed at `0x7d2C41C76dc3EA1E9A0F10B1d0EB3aCB78E22B64`

## Support

- Full guide: `AGENT_DEVELOPMENT_GUIDE.md`
- Examples: See `ExampleAgent.sol` and `SimpleBettingAgent.sol`
- Deployment: Use `scripts/deploy-example-agent.js`

For quick questions, DM us on Twitter: https://x.com/eternaxLabs

Happy building! 🎉