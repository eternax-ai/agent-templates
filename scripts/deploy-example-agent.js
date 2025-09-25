const { ethers } = require("hardhat");

async function main() {
    console.log("Deploying Example Agents...");
    
    // Get the deployer account and network
    const [deployer] = await ethers.getSigners();
    const network = await ethers.provider.getNetwork();
    console.log("Deploying with account:", deployer.address);
    console.log("Network:", network.name);


    // Configuration for agents
    const EXECUTION_INTERVAL = 30; // 30 blocks between executions (current chain limit is 500 blocks)
    const MAX_EXECUTIONS = 10;    // Maximum 10 executions 

    try {

        // Deploy SimpleBettingAgent
        console.log("\n Deploying SimpleBettingAgent...");

        const MarketOracle = "0x4D589B49d8763C9FaaE726d464E3B9F53347BED4"; // Actual oracle address
        const PredictionMarket = "0xB27B171a18B589E086D2f11148D3F0C8f1f8032c"; // Actual market address
        
        const SimpleBettingAgent = await ethers.getContractFactory("SimpleBettingAgent");
        const bettingAgent = await SimpleBettingAgent.connect(deployer).deploy(
            EXECUTION_INTERVAL, 
            MAX_EXECUTIONS, 
            MarketOracle, 
            PredictionMarket
        );
        await bettingAgent.waitForDeployment();
        const bettingAgentAddress = await bettingAgent.getAddress();
        console.log("SimpleBettingAgent deployed to:", bettingAgentAddress);

        // Fund the agent with 5 ETX
        console.log("Funding SimpleBettingAgent with 5 testETX...");
        const fundTx = await deployer.sendTransaction({
            to: bettingAgentAddress,
            value: ethers.parseEther("5") // 5 testETX
        });
        await fundTx.wait();
        const balance = await ethers.provider.getBalance(bettingAgentAddress);
        console.log("SimpleBettingAgent funded with 5 testETX, current balance:", ethers.formatEther(balance), "testETX");

        // Activate the agent
        console.log("Activating SimpleBettingAgent...");
        const activateTx = await bettingAgent.setActive(true);
        await activateTx.wait();
        console.log("SimpleBettingAgent activated");

        // Setup periodic execution
        console.log("\nSetting up periodic execution...");
        
        const scheduleTx = await bettingAgent.setupPeriodicExecution();
        const scheduleReceipt = await scheduleTx.wait();
        console.log("SimpleBettingAgent scheduled with transaction hash:", scheduleReceipt.hash);

        // Display agent state
    
        const bettingState = await bettingAgent.getState();
        console.log("SimpleBettingAgent State:", {
            requestsSent: bettingState[0].toString(),
            responsesReceived: bettingState[1].toString(),
            lastRequest: bettingState[2].toString(),
            isRequesting: bettingState[3],
            isActive: bettingState[4]
        });

        // Get agent-specific status
        console.log("\nAgent-Specific Status:");

        const bettingStats = await bettingAgent.getBettingStats();
        console.log("SimpleBettingAgent Stats:", {
            totalBetsPlaced: bettingStats[0].toString(),
            totalWinnings: bettingStats[1].toString()
        });

        console.log("\nDeployment completed successfully!");
        console.log("\nSummary:");
        console.log("=".repeat(50));
        console.log(`SimpleBettingAgent: ${bettingAgentAddress}`);
        console.log(`Execution Interval: ${EXECUTION_INTERVAL} blocks`);
        console.log(`Max Executions: ${MAX_EXECUTIONS}`);
        console.log("Agent is active and scheduled for periodic execution");

        // Save deployment info
        const deploymentInfo = {
            network: network.name,
            timestamp: new Date().toISOString(),
            deployer: deployer.address,
            contracts: {
                SimpleBettingAgent: {
                    address: bettingAgentAddress,
                    executionInterval: EXECUTION_INTERVAL,
                    maxExecutions: MAX_EXECUTIONS,
                    oracleAddress: MarketOracle,
                    marketAddress: PredictionMarket
                }
            }
        };

        console.log("\nDeployment info saved to deployment.json");
        require('fs').writeFileSync('deployment.json', JSON.stringify(deploymentInfo, null, 2));

    } catch (error) {
        console.error("Deployment failed:", error);
        process.exit(1);
    }
}

// Handle errors
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });