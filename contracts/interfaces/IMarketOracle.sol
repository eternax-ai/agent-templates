// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

interface IMarketOracle {
    enum MarketStatus {
        Pending,    // market is open for positions
        Active,     // market event is underway
        Cancelled,  // market was cancelled
        Resolved    // market has been resolved with outcome
    }

    /// @notice Get all markets that are still pending resolution
    /// @return Array of market IDs
    function getPendingMarkets() external view returns (bytes32[] memory);

    /// @notice Get all markets, including resolved ones
    /// @return Array of market IDs
    function getAllMarkets() external view returns (bytes32[] memory);

    /// @notice Check if a market exists
    /// @param _marketId The ID of the market to check
    /// @return True if the market exists
    function marketExists(bytes32 _marketId) external view returns (bool);

    /// @notice Get detailed information about a specific market
    /// @param _marketId The ID of the market to query
    /// @return id Market identifier
    /// @return name Human-readable market name
    /// @return description Detailed market description
    /// @return expirationDate When the market expires/resolves
    /// @return status Current market status
    /// @return resolvedOutcome Final outcome (false=0, true=1, unresolved=-1)
    function getMarket(bytes32 _marketId) external view returns (
        bytes32 id,
        string memory name,
        string memory description,
        uint expirationDate,
        MarketStatus status,
        int8 resolvedOutcome
    );

    /// @notice Get the most recent market
    /// @param _pending If true, returns most recent pending market. If false, includes resolved markets
    /// @return id Market identifier
    /// @return name Human-readable market name
    /// @return description Detailed market description
    /// @return expirationDate When the market expires/resolves
    /// @return status Current market status
    /// @return resolvedOutcome Final outcome (false=0, true=1, unresolved=-1)
    function getMostRecentMarket(bool _pending) external view returns (
        bytes32 id,
        string memory name,
        string memory description,
        uint expirationDate,
        MarketStatus status,
        int8 resolvedOutcome
    );

    /// @notice Test the connection to the oracle
    /// @return True if connection is successful
    function testConnection() external pure returns (bool);

    /// @notice Add test data (only for testing environments)
    function addTestData() external;

    /// @notice Resolves a market with the given outcome
    /// @param _marketId The ID of the market to resolve
    /// @param _resolvedOutcome The outcome to resolve the market to (0 for NO, 1 for YES)
    function resolveMarket(bytes32 _marketId, MarketStatus _status, int8 _resolvedOutcome) external;
} 