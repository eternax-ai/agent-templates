// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMarketOracle.sol";

/// @title IPredictionMarket
/// @notice Interface for the prediction market contract that handles positions and payouts
interface IPredictionMarket {
    struct Position {
        address user;
        bytes32 marketId;
        uint256 amount;
        bool prediction;  // false = No, true = Yes
        bool claimed;     // Whether winnings have been claimed 
    }

    /// @notice Emitted when a position is taken
    ///Signature 0xf7819f15894aaf242399694d279b5e4b1080db70eb6b2c219b16f68064fd751d
    event PositionTaken(address indexed user, bytes32 indexed marketId, bool prediction, uint256 amount);
    
    /// @notice Emitted when winnings are claimed
    ///Signature 0xac1dfcff29900d7010c04a6028e48814b8a49daf045127abd10a4636d1d49115
    event WinningsClaimed(bytes32 indexed marketId, address indexed user, uint256 amount);
    
    /// @notice Emitted when a market is finalized with pools calculated
    ///Signature 0xbc77879f29c612d96ddfc9737c09b7609fbcea8b388490afa39ed09f50d78624
    event MarketFinalized(bytes32 indexed marketId, uint256 totalPool, uint256 winningPool);

    /// @notice Takes a position on a market
    /// @param _marketId The ID of the market to take position on
    /// @param _prediction true for Yes, false for No
    function takePosition(bytes32 _marketId, bool _prediction) external payable;

    /// @notice Gets all currently open markets
    /// @return Array of market IDs
    function getPendingMarkets() external view returns (bytes32[] memory);

    /// @notice Claims winnings for a resolved market
    /// @param _user The address of the user
    function claimWinnings(address _user) external;

    /// @notice Finalizes a market
    /// @param _marketId The ID of the market
    /// @return true if the market was finalized successfully
    function finalizeMarket(bytes32 _marketId) external returns (bool);

    /// @notice Gets a user's position for a specific market
    /// @param _user The address of the user
    /// @param _marketId The ID of the market
    /// @return position The Position struct
    function getUserMarketPosition(address _user, bytes32 _marketId) external view returns (Position memory);

    /// @notice Gets all positions for a user
    /// @param _user The address of the user
    /// @return positions Array of Position structs
    function getUserPositions(address _user) external view returns (Position[] memory);

    /// @notice Gets all positions for a specific market
    /// @param _marketId The ID of the market
    /// @return positions Array of Position structs for the market
    function getMarketPositions(bytes32 _marketId) external view returns (Position[] memory);

    /// @notice Allows the owner to withdraw collected fees
    function withdrawFees() external;

    /// @notice Gets the current amount of collected fees
    /// @return The amount of fees collected but not yet withdrawn
    function getCollectedFees() external view returns (uint256);

    /// @notice Get total winnings for a user across all markets
    /// @param _user The user address
    /// @return totalWinnings Total winnings for the user
    function getUserWinnings(address _user) external view returns (uint256 totalWinnings);

} 