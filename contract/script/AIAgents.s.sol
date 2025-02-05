// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/AIAgents.sol";

contract AIAgentsScript is Script {
    function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the AIAgents contract
        AIAgents aiAgents = new AIAgents();

        // Register an agent
        address agentAddress = address(0x1);
        vm.prank(agentAddress);
        aiAgents.registerAgent("Agent One");

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
} 