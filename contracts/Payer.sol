// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IScheduler.sol";
import "./interfaces/IWETX.sol";

// @title Payer
// @author Example contract template for eternaX Network
// @notice This contract is used to pay a payee a fixed amount of tokens every X blocks for Y times. Customizable.

contract Payer {
    address public constant SCHEDULER_PRECOMPILE = 0x0000000000000000000000000000000000000402;
    
    address public owner;
    address public payee;
    IWETX public token;
    uint256 public totalReceived;
    uint256 public totalPaid;
    uint32 public scheduledTransactionId;
    bool public isScheduled;
    
    event TokensReceived(address from, uint256 amount);
    event PaymentSent(address to, uint256 amount, uint256 timestamp);
    event SchedulingFailed(string reason);
    event PaymentScheduled(uint32 transactionId, uint256 targetBlock, uint32 interval);
    
    constructor(address _payee, address _token) {
        owner = msg.sender;
        payee = _payee;
        token = IWETX(_token);
        totalReceived = 0;
        totalPaid = 0;
        isScheduled = false;
    }
    
    // Function to receive tokens from owner
    function receiveTokens(uint256 amount) external {
        require(msg.sender == owner, "Only owner can send tokens");
        require(amount > 0, "Amount must be positive");
        
        // Transfer tokens from owner to this contract
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        
        totalReceived += amount;
        emit TokensReceived(msg.sender, amount);
    }
    
    // Function to receive ETX and convert to WETX
    function receiveETX() external payable {
        require(msg.sender == owner, "Only owner can send ETX");
        require(msg.value > 0, "Must send ETX");
        
        // Convert ETX to WETX
        token.deposit{value: msg.value}();
        
        totalReceived += msg.value;
        emit TokensReceived(msg.sender, msg.value);
    }
    
    // Function to be called by scheduled execution
    function sendPayment() external returns (bool) {
        require(msg.sender == address(this), "Only self-execution allowed");
        require(token.balanceOf(address(this)) >= 1e18, "Insufficient balance for payment");
        
        uint256 paymentAmount = 1e18; // 1 ETX (18 decimals)
        
        // Convert WETX to ETX and send to payee
        token.withdraw(paymentAmount);
        payable(payee).transfer(paymentAmount);
        
        totalPaid += paymentAmount;
        emit PaymentSent(payee, paymentAmount, block.timestamp);
        
        return true;
    }
    
    // Setup recurring payments to Balthazar
    function setupRecurringPayments() external returns (uint32) {
        require(msg.sender == owner, "Only owner can setup recurring payments");
        require(!isScheduled, "Payments already scheduled");
        require(token.balanceOf(address(this)) >= 9e18, "Insufficient balance for 9 payments");
        
        // Get the function selector for sendPayment
        bytes4 functionSelector = this.sendPayment.selector;
        
        // Start in 3 blocks
        uint256 targetBlock = block.number + 3;
        
        // Schedule the recurring payments: every 3 blocks, 9 executions
        try IScheduler(SCHEDULER_PRECOMPILE).scheduleRecurringCall(
            targetBlock,         // target block number
            address(this),       // target contract (this contract)
            0,                   // no ETH value
            abi.encodePacked(functionSelector), // function call data
            100000,              // gas limit
            0,                   // auto-assign nonce
            3,                   // interval in blocks
            9                    // 9 executions
        ) returns (uint32 transactionId) {
            scheduledTransactionId = transactionId;
            isScheduled = true;
            emit PaymentScheduled(transactionId, targetBlock, 3);
            return transactionId;
        } catch Error(string memory reason) {
            emit SchedulingFailed(reason);
            revert(reason);
        } catch {
            emit SchedulingFailed("Unknown scheduling error");
            revert("Scheduling failed");
        }
    }
    
    // Manual payment for testing
    function manualPayment() external {
        require(msg.sender == owner, "Only owner can manually send payment");
        require(token.balanceOf(address(this)) >= 1e18, "Insufficient balance");
        
        uint256 paymentAmount = 1e18; // 1 ETX (18 decimals)
        
        // Convert WETX to ETX and send to payee
        token.withdraw(paymentAmount);
        payable(payee).transfer(paymentAmount);
        
        totalPaid += paymentAmount;
        emit PaymentSent(payee, paymentAmount, block.timestamp);
    }
    
    // Get current state
    function getState() external view returns (
        uint256 _totalReceived,
        uint256 _totalPaid,
        uint256 _currentBalance,
        bool _isScheduled,
        uint32 _scheduledTransactionId
    ) {
        return (
            totalReceived,
            totalPaid,
            token.balanceOf(address(this)),
            isScheduled,
            scheduledTransactionId
        );
    }
    
    // Get payee's ETX balance
    function getPayeeBalance() external view returns (uint256) {
        return payee.balance;
    }
} 