require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1, // Low runs value for smaller contract size
      },
      viaIR: true, // Enable IR-based optimizer for better size reduction
    },
  },
  paths: {
    sources: "./contracts"
  },
  networks: {
    testnet1: {
      traces: true,
      debug: true,
      url: "https://rpc.eternax.ai",
      wsUrl: "wss://rpc.eternax.ai",
      accounts: [
        "0x27d47a16505c698209cf2dd960067dd13303700ef5f7aaf334ba7df6d3098fb4", // 5EAM9HBp135VVjhFHAu8Z3Z6GK3Q3E2a5Uy1q5bPn2TtJevx
        "0x428ea40a02f17f511b4dbb75f070b3ee7238080452895855137b45f08fface59", // 5EPKEM82BALgGfFjiDo2QXkY8Kn4D7arbJJaz5UHTTLy65DY
        "0xabb77341843540c6117b007da54743894f3251696897217ce95fb489c9b5fd4d", // 5HNBqnQ7WGbMavQeUthd1anPoAFBp99dtiprBCwYg6spZAyW
      ],
      chainId: 42,
      timeout: 20000,
      gas: 2100000,
      gasPrice: 8000000000,
      loggingEnabled: true
    }
  }
};