# Schema-Based Callback Integration

## Overview

The EternaX neural routing system supports **schema-based callbacks** that automatically parse structured AI responses and pass them as typed parameters to smart contract callbacks. This eliminates the need for contracts to parse JSON responses, making agent loops more gas-efficient and type-safe.

## How It Works

### 1. Contract Requests Inference with Schema

```solidity
// Define JSON schema for structured output
string memory jsonSchema = '{"type":"object","properties":{"bet":{"type":"string","enum":["yes","no"]},"confidence":{"type":"number","minimum":0,"maximum":1},"reason":{"type":"string"}},"required":["bet","confidence","reason"]}';

// Request inference with schema
neuralRouting.requestInference(
    inputData,
    "llama3.1:8b-instruct-q8_0",
    false,
    bytes(jsonSchema), // JSON schema as bytes
    address(this),
    functionSelector,  // Callback function selector
    "",
    150000
);
```

### 2. Neural Node Processes and Validates

The neural node:
- Receives the inference request with schema
- Calls the AI model with schema-guided prompts
- Validates the response against the provided schema
- Parses the JSON response into structured data

### 3. Node ABI Encodes Parameters

The node automatically ABI encodes the response parameters based on the schema:

For schema: `{"bet": "string", "confidence": "number", "reason": "string"}`
Encodes as: `(bytes32 requestId, string bet, uint256 confidence, string reason)`


### 4. Contract Receives Typed Parameters

```solidity
function processStructuredAIResponse(
    bytes32 requestId, 
    string memory bet, 
    uint256 confidence, 
    string memory reason
) external {
    // Parameters are already parsed and typed!
    require(msg.sender == NEURAL_ROUTING, "Only Neural Routing precompile");
    
    // Use the structured data directly
    if (keccak256(abi.encodePacked(bet)) == keccak256(abi.encodePacked("yes")) && confidence >= 800000) {
        // High confidence "yes" - trigger action
    }
}
```

## Supported Schema Types

The system supports these JSON schema types with specific restrictions:

### String
```json
{"type": "string"}
```
- Encoded as dynamic string parameter
- Supports enum constraints: `{"type": "string", "enum": ["yes", "no"]}`
- **Restrictions**: No nested objects or arrays as values

### Integer
```json
{"type": "integer"}
```
- Encoded as `uint256` (direct integer value, no scaling)
- Supports min/max constraints: `{"type": "integer", "minimum": 0, "maximum": 100}`
- **Recommended**: Use integers instead of floats for better gas efficiency
- **Restrictions**: No floating-point numbers

### Boolean
```json
{"type": "boolean"}
```
- Encoded as `uint256` (0 or 1)
- **Restrictions**: No nested objects or arrays

## Schema Restrictions

### Not Supported
- **Nested Objects**: `{"type": "object", "properties": {"nested": {"type": "object"}}}`
- **Arrays**: `{"type": "array", "items": {"type": "string"}}`
- **Floating-Point Numbers**: Use integers instead
- **Number Type**: `{"type": "number"}` - not supported in ABI encoding
- **Complex Types**: `null`, `undefined`, or custom types
- **Mixed Types**: Union types or `oneOf`/`anyOf` schemas

### Supported
- **Flat Objects**: Only top-level properties with simple types
- **String Enums**: `{"type": "string", "enum": ["option1", "option2"]}`
- **Integer Ranges**: `{"type": "integer", "minimum": 0, "maximum": 100}`
- **Required Fields**: `{"required": ["field1", "field2"]}`

### Example Valid Schema
```json
{
  "type": "object",
  "properties": {
    "action": {
      "type": "string",
      "enum": ["buy", "sell", "hold"]
    },
    "confidence": {
      "type": "integer",
      "minimum": 0,
      "maximum": 100
    },
    "reason": {
      "type": "string"
    }
  },
  "required": ["action", "confidence", "reason"]
}
```

### Example Invalid Schema
```json
{
  "type": "object",
  "properties": {
    "nested": {
      "type": "object",  // Nested objects not supported
      "properties": {
        "value": {"type": "string"}
      }
    },
    "list": {
      "type": "array",   // Arrays not supported
      "items": {"type": "string"}
    },
    "score": {
      "type": "number"   // Number type not supported
    }
  }
}
```

## Handling Decimal Values

Since floating-point numbers are not supported in ABI encoding, handle decimal values as integers on the contract side:

### Currency Example
```solidity
// Schema: {"price": "integer"} - AI returns price in cents
function processStructuredAIResponse(
    bytes32 requestId, 
    uint256 price  // Price in cents (e.g., 105 = $1.05)
) external {
    // Convert cents to dollars for display
    uint256 dollars = price / 100;
    uint256 cents = price % 100;
    
    // Use the price in cents for calculations
    if (price > 10000) { // $100.00
        // Handle expensive items
    }
}
```

### Percentage Example
```solidity
// Schema: {"confidence": "integer", "minimum": 0, "maximum": 10000}
// AI returns confidence as basis points (0-10000 = 0-100%)
function processStructuredAIResponse(
    bytes32 requestId, 
    uint256 confidence  // Basis points (e.g., 8500 = 85.00%)
) external {
    // Convert to percentage for display
    uint256 percentage = confidence / 100; // 85%
    uint256 decimals = confidence % 100;   // 00
    
    // Use basis points for precise calculations
    if (confidence >= 8000) { // 80% or higher
        // High confidence action
    }
}
```

### Precision Example
```solidity
// Schema: {"amount": "integer"} - AI returns amount with 6 decimal places
function processStructuredAIResponse(
    bytes32 requestId, 
    uint256 amount  // Amount with 6 decimal places (e.g., 1500000 = 1.5)
) external {
    // Convert to standard units
    uint256 whole = amount / 1000000;
    uint256 fraction = amount % 1000000;
    
    // Use precise amount for calculations
    if (amount > 1000000) { // Greater than 1.0
        // Handle significant amounts
    }
}
```

### Best Practices
- **Choose Appropriate Precision**: Use the minimum precision needed for your use case
- **Document the Scale**: Clearly document what the integer represents
- **Handle Overflow**: Ensure your integer range can handle the scaled values
- **Gas Efficiency**: Higher precision means larger numbers and more gas

## Example Implementations

### Binary Decision Agent
```solidity
// Schema: {"bet": "yes/no", "confidence": 0-1, "reason": "explanation"}
function processStructuredAIResponse(
    bytes32 requestId, 
    string memory bet, 
    uint256 confidence, 
    string memory reason
) external {
    if (keccak256(abi.encodePacked(bet)) == keccak256(abi.encodePacked("yes")) && confidence >= 800000) {
        // Execute high-confidence "yes" action
        executeTrade();
    }
}
```

### Multi-Choice Agent
```solidity
// Schema: {"action": "buy/sell/hold", "urgency": "low/medium/high", "reasoning": "explanation"}
function processStructuredAIResponse(
    bytes32 requestId, 
    string memory action, 
    string memory urgency, 
    string memory reasoning
) external {
    if (keccak256(abi.encodePacked(action)) == keccak256(abi.encodePacked("buy")) && 
        keccak256(abi.encodePacked(urgency)) == keccak256(abi.encodePacked("high"))) {
        // Execute urgent buy action
        executeUrgentBuy();
    }
}
```

### Sentiment Analysis Agent
```solidity
// Schema: {"sentiment": "positive/negative/neutral", "score": -1 to 1, "keywords": ["list"]}
function processStructuredAIResponse(
    bytes32 requestId, 
    string memory sentiment, 
    uint256 score, 
    string memory keywords
) external {
    if (keccak256(abi.encodePacked(sentiment)) == keccak256(abi.encodePacked("positive")) && score >= 500000) {
        // Handle positive sentiment
        handlePositiveSentiment();
    }
}
```

## Technical Details

### ABI Encoding Algorithm

The node follows this algorithm to encode callbacks:

**For Schema-Based Callbacks:**
1. **Parse Schema**: Extract properties and types from JSON schema
2. **Sort Properties**: Ensure consistent parameter ordering
3. **Calculate Offsets**: For dynamic types (strings), calculate data offsets
4. **Encode Static Parameters**: Encode numbers, booleans directly
5. **Encode Dynamic Data**: Append string data with proper padding
6. **Validate**: Ensure all required properties are present

**For Empty Schema Callbacks:**
1. **Encode Request ID**: 32-byte request identifier
2. **Encode Response Offset**: 32-byte offset to response data
3. **Encode Response Length**: 32-byte length of response data
4. **Encode Response Data**: Response bytes with proper padding
5. **Append Callback Data**: Additional callback parameters

### Error Handling

- **Schema Validation**: Invalid schemas are rejected at request time
- **Response Validation**: AI responses must match schema exactly
- **Fallback**: If schema encoding fails, falls back to proper ABI-encoded legacy callback
- **Graceful Degradation**: All callbacks use proper ABI encoding for reliability
- **Consistent Behavior**: Both success and fallback paths use standards-compliant encoding