// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./BaseAgent.sol";
import "./interfaces/IMarketOracle.sol";
import "./interfaces/IPredictionMarket.sol";

/**
 * @title SimpleBettingAgent
 * @dev Advanced example showing how to build a betting agent using BaseAgent template.
 * 
 * This agent demonstrates:
 * - Simple betting agent focused on market analysis
 * - Integration with prediction markets and oracles
 * - Confidence-based bet sizing
 * - Automated betting based on AI predictions
 * - Native ETX token handling
 * 
 * Features:
 * - Market analysis with confidence-based bet sizing
 * - Automated winnings claiming
 * - Position tracking and management
 * - Native ETX token handling
 * 
 * This follows the BaseAgent template properly by:
 * - Implementing all 4 abstract functions
 * - Using configurable schemas (not constructor parameters)
 * - Following the established patterns from the guide
 * 
 * @author Template Example for Eternax Network
 * @notice This demonstrates advanced BaseAgent usage for prediction markets
 * @dev Inherits from BaseAgent for core functionality
 */
contract SimpleBettingAgent is BaseAgent {
    // Betting state
    struct BetPosition {
        bytes32 marketId;
        bool isActive;
        uint256 amount;
        bool prediction; // true for YES, false for NO
        uint256 entryTime;
        string reasoning;
        uint256 confidence;
    }
    
    // Agent configuration
    struct BettingConfig {
        uint256 maxBetSize;
        uint256 minConfidence; // minimum confidence to place bet (0-100)
        uint256 riskThreshold; // maximum risk level (0-100)
        bool enableHighRiskBets;
        uint256 maxActivePositions;
    }
    
    // External contracts
    IMarketOracle public marketOracle;
    IPredictionMarket public predictionMarket;
    
    // Betting state
    mapping(bytes32 => BetPosition) public positions; // marketId => position
    mapping(bytes32 => bytes32) private requestToMarket; // requestId => marketId
    mapping(bytes32 => bool) private positionTaken; // marketId => has position been taken
    BettingConfig public bettingConfig;
    
    uint256 public totalBetsPlaced;
    uint256 public totalWinnings;
    
    // Constants
    uint256 public constant MINIMUM_BET = 1e18; // 1 ETX
    uint256 public constant MAXIMUM_BET = 10e18; // 10 ETX
    
    // Events specific to betting
    event BettingConfigUpdated(BettingConfig config);
    event BetPlaced(bytes32 indexed marketId, bool prediction, uint256 amount, uint256 confidence, string reasoning);
    event BetWon(bytes32 indexed marketId, uint256 winnings);
    event BetLost(bytes32 indexed marketId, uint256 amount);
    event RiskWarning(string warning, uint256 riskLevel);
    event WinningsClaimed(bytes32 indexed marketId, uint256 amount);
    
    constructor(
        uint256 _executionInterval, 
        uint32 _maxExecutions,
        address _marketOracle,
        address _predictionMarket
    ) 
        BaseAgent(_executionInterval, _maxExecutions)
    {
        marketOracle = IMarketOracle(_marketOracle);
        predictionMarket = IPredictionMarket(_predictionMarket);
        
        // Initialize betting configuration
        bettingConfig = BettingConfig({
            maxBetSize: 5e18, // 5 ETX max bet
            minConfidence: 70, // 70% minimum confidence
            riskThreshold: 80, // 80% max risk tolerance
            enableHighRiskBets: false,
            maxActivePositions: 3
        });
        
        totalBetsPlaced = 0;
        totalWinnings = 0;
    }
    
    // =============================================================================
    // IMPLEMENTATION OF ABSTRACT FUNCTIONS FROM BASEAGENT
    // =============================================================================
    
    /**
     * @dev Execute betting logic - analyze markets and place bets
     */
    function executeAgentLogic() external override onlySelf whenActive returns (bool success) {
    
        claimAllWinnings();
        
        // Check if we have sufficient balance for betting
        if (address(this).balance < MINIMUM_BET) {
            return false; // Not enough funds to bet
        }
        
        // Do market analysis and betting
        return _analyzeAvailableMarkets();
    }
    
    /**
     * @dev Configure AI models and schemas for market analysis 
     */
    function getInferenceConfig(string memory /* context */) internal pure override returns (InferenceConfig memory config) {
        // Only support market analysis for betting decisions
        config = InferenceConfig({
            modelName: "llama3.1:8b-instruct-q8_0",
            requiresTee: false,
            jsonSchema: '{"type":"object","properties":{"bet":{"type":"string","enum":["yes","no"]},"confidence":{"type":"integer","minimum":0,"maximum":100},"reason":{"type":"string"}},"required":["bet","confidence","reason"]}',
            callbackGasLimit: 1000000,
            functionSelector: 0x57f97e61 // processStructuredAIResponse(bytes32,string,uint256,string) selector
        });
    }
    
    /**
     * @dev Process AI responses and execute betting decisions
     */
    function processAIResponse(bytes32 requestId, string memory response) internal override {
        // For market analysis, we use structured callback, so this won't be called
        // The structured callback processStructuredAIResponse will handle it
    }
    
    /**
     * @dev Structured callback function for market analysis - receives parsed parameters
     * @param requestId The unique identifier for the inference request
     * @param bet The prediction result ("yes" or "no")
     * @param confidence The confidence level (0-100)
     * @param reason The reasoning behind the prediction
     * @notice Only callable by the Neural Routing precompile with validated structured data
     */
    function processStructuredAIResponse(bytes32 requestId, string memory bet, uint256 confidence, string memory reason) external {
        // Only allow Neural Routing precompile to call this function
        require(msg.sender == NEURAL_ROUTING, "Only Neural Routing precompile can provide responses");
        
        // Validate the structured response
        require(
            keccak256(abi.encodePacked(bet)) == keccak256(abi.encodePacked("yes")) ||
            keccak256(abi.encodePacked(bet)) == keccak256(abi.encodePacked("no")),
            "Invalid bet value - must be 'yes' or 'no'"
        );
        require(confidence <= 100, "Confidence must be <= 100");
        
        // Get the marketId from the original request
        bytes32 marketId = requestToMarket[requestId];
        if (marketId == bytes32(0)) {
            return; // No market associated with this request
        }
        
        // Check if we already have a position on this market
        if (positionTaken[marketId]) {
            return; // Already bet on this market
        }
        
        // Check if we have sufficient balance
        if (address(this).balance < MINIMUM_BET) {
            return; // Insufficient balance
        }
        
        // Calculate bet amount based on confidence (simplified version)
        uint256 betAmount = _calculateBetAmount(confidence);
        
        // Convert string outcome to bool for the prediction market
        bool isYes = keccak256(abi.encodePacked(bet)) == keccak256(abi.encodePacked("yes"));
        
        // Place the bet
        _placeBetFromAI(marketId, isYes, betAmount, confidence, reason);
        
        // Clean up
        delete requestToMarket[requestId];
    }
    
    /**
     * @dev Validate betting agent configuration
     */
    function validateConfiguration() internal view override returns (bool isValid) {
        return bettingConfig.maxBetSize >= MINIMUM_BET &&
               bettingConfig.maxBetSize <= MAXIMUM_BET &&
               bettingConfig.minConfidence <= 100 &&
               bettingConfig.riskThreshold <= 100 &&
               bettingConfig.maxActivePositions > 0 &&
               address(marketOracle) != address(0) &&
               address(predictionMarket) != address(0);
    }
    
    // =============================================================================
    // BETTING-SPECIFIC FUNCTIONS
    // =============================================================================
    
    /**
     * @dev Analyze available markets and request AI prediction
     */
    function _analyzeAvailableMarkets() internal returns (bool) {
        // Find an available market to analyze
        bytes32 marketId = _findBestMarket();
        if (marketId == bytes32(0)) {
            return false; // No suitable markets found
        }
        
        // Get market details
        (, string memory name, string memory description, , , ) = marketOracle.getMarket(marketId);
        
        // Create market analysis prompt
        string memory prompt = string(abi.encodePacked(
            "Analyze this prediction market for betting: '", name, "' - ", description,
            ". Available balance: ", _uintToString(address(this).balance / 1e18), " ETX",
            ". Should I bet on this market? Provide prediction (yes/no), confidence level, reasoning, and follow the JSON schema provided."
        ));
        
        // Request inference using Neural Routing precompile directly (like WorkingBettingAgent)
        bytes memory inputData = bytes(prompt);
        string memory jsonSchema = '{"type":"object","properties":{"bet":{"type":"string","enum":["yes","no"]},"confidence":{"type":"integer","minimum":0,"maximum":100},"reason":{"type":"string"}},"required":["bet","confidence","reason"]}';
        bytes memory outputSchema = bytes(jsonSchema);
        
        try neuralRouting.requestInference(
            inputData,
            "llama3.1:8b-instruct-q8_0",
            false, // No TEE required
            outputSchema,
            address(this),
            0x57f97e61, // processStructuredAIResponse selector
            "", // No additional data
            1000000 // Gas limit for callback
        ) returns (bytes32 requestId) {
            requestToMarket[requestId] = marketId;
            return true;
        } catch Error(string memory /*reason*/) {
            return false;
        }
    }
    
    
    
    /**
     * @dev Calculate bet amount based on confidence level
     * @param confidence The confidence level (0-100)
     * @return betAmount The calculated bet amount
     */
    function _calculateBetAmount(uint256 confidence) internal view returns (uint256) {
        // Linear interpolation between MINIMUM_BET and maxBetSize based on confidence
        uint256 range = bettingConfig.maxBetSize - MINIMUM_BET;
        uint256 confidenceAmount = (confidence * range) / 100;
        return MINIMUM_BET + confidenceAmount;
    }
    
    /**
     * @dev Place a bet from AI analysis with proper error handling
     * @param marketId The market to bet on
     * @param isYes Whether to bet yes or no
     * @param amount The bet amount
     * @param confidence The confidence level
     * @param reason The reasoning
     */
    function _placeBetFromAI(bytes32 marketId, bool isYes, uint256 amount, uint256 confidence, string memory reason) internal {
        require(amount >= MINIMUM_BET && amount <= bettingConfig.maxBetSize, "Invalid bet amount");
        require(confidence >= bettingConfig.minConfidence, "Confidence too low");
        require(address(this).balance >= amount, "Insufficient balance");
        require(!positionTaken[marketId], "Already have position on this market");
        
        try predictionMarket.takePosition{value: amount}(marketId, isYes) {
            // Record the position
            positions[marketId] = BetPosition({
                marketId: marketId,
                isActive: true,
                amount: amount,
                prediction: isYes,
                entryTime: block.timestamp,
                reasoning: reason,
                confidence: confidence
            });
            
            positionTaken[marketId] = true;
            totalBetsPlaced++;
            
            emit BetPlaced(marketId, isYes, amount, confidence, reason);
            
        } catch Error(string memory errorReason) {
            emit RiskWarning(string(abi.encodePacked("Bet failed: ", errorReason)), 0);
        }
    }
    
   
    /**
     * @dev Find the best available market to bet on
     */
    function _findBestMarket() internal view returns (bytes32) {
        try marketOracle.getPendingMarkets() returns (bytes32[] memory pendingMarkets) {
            for (uint i = 0; i < pendingMarkets.length; i++) {
                bytes32 marketId = pendingMarkets[i];
                if (!positionTaken[marketId]) {
                    return marketId;
                }
            }
        } catch {
            // If getPendingMarkets fails, try getMostRecentMarket
            try marketOracle.getMostRecentMarket(true) returns (
                bytes32 id, string memory, string memory, uint, IMarketOracle.MarketStatus status, int8
            ) {
                if (status == IMarketOracle.MarketStatus.Pending && !positionTaken[id]) {
                    return id;
                }
            } catch {
                // Return no market if all else fails
            }
        }
        return bytes32(0);
    }
    
    
    /**
     * @dev Claim all available winnings
     * @notice Uses single call to PredictionMarket for maximum gas efficiency
     */
    function claimAllWinnings() public {
        require(msg.sender == owner || msg.sender == address(this), "Only owner or self-execution can claim");
        
        // Get total winnings from PredictionMarket (single call)
        try predictionMarket.getUserWinnings(address(this)) returns (uint256 availableWinnings) {
            if (availableWinnings > 0) {
                // Claim all winnings in single call
                try predictionMarket.claimWinnings(address(this)) {
                    // Calculate winnings received
                    uint256 winnings = address(this).balance;
                    if (winnings > 0) {
                        totalWinnings += winnings;
                        emit BetWon(bytes32(0), winnings); // Use 0 for bulk claim
                    }
                } catch Error(string memory reason) {
                    emit RiskWarning(string(abi.encodePacked("Claim failed: ", reason)), 0);
                } catch (bytes memory) {
                    emit RiskWarning("Claim failed: Unknown error", 0);
                }
            }
        } catch Error(string memory reason) {
            emit RiskWarning(string(abi.encodePacked("Prediction market query failed: ", reason)), 0);
        } catch {
            // If getUserWinnings fails, we can't auto-claim
            emit RiskWarning("Auto claim failed: Cannot get user winnings", 0);
        }
    }

    /**
     * @dev Update betting configuration
     */
    function updateBettingConfig(BettingConfig memory newConfig) external onlyOwner {
        require(newConfig.maxBetSize >= MINIMUM_BET, "Max bet too small");
        require(newConfig.maxBetSize <= MAXIMUM_BET, "Max bet too large");
        require(newConfig.minConfidence <= 100, "Invalid confidence threshold");
        require(newConfig.riskThreshold <= 100, "Invalid risk threshold");
        
        bettingConfig = newConfig;
        emit BettingConfigUpdated(newConfig);
    }
    
    /**
     * @dev Get current betting statistics
     */
    function getBettingStats() external view returns (
        uint256 _totalBetsPlaced,
        uint256 _totalWinnings
    ) {
        return (
            totalBetsPlaced,
            totalWinnings
        );
    }
    
    /**
     * @dev Check if we have winnings available (like WorkingBettingAgent)
     * @return winnings The amount of winnings available (0 if none)
     */
    function checkWinnings() external view returns (uint256 winnings) {
        return predictionMarket.getUserWinnings(address(this));
    }
    
    /**
     * @dev Emergency function to close all positions and stop betting
     */
    function emergencyStopBetting() external onlyOwner {
        isActive = false;
        // In production, might also try to close all active positions
        emit RiskWarning("Emergency stop activated", 100);
    }
    
    /**
     * @dev Deposit native ETX to the agent for betting
     */
    function deposit() external payable {
        require(msg.value > 0, "Must deposit some ETX");
        // Native ETX is automatically added to contract balance
    }
    
    /**
     * @dev Withdraw native ETX from the agent (owner only)
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        require(amount > 0, "Amount must be positive");
        
        payable(owner).transfer(amount);
    }
    
}