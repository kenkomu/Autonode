// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/AIAgents.sol";

contract AIAgentsTest is Test {
    AIAgents private aiAgents;
    address private agent1 = address(0x1);
    address private agent2 = address(0x2);
    address private user = address(0x3);

    function setUp() public {
        aiAgents = new AIAgents();
    }

    function testAgentRegistration() public {
        vm.prank(agent1);
        aiAgents.registerAgent("Agent One");

        (string memory name, bool isActive) = aiAgents.getAgent(agent1);
        assertEq(name, "Agent One");
        assertTrue(isActive);
    }

    function testAgentCannotRegisterTwice() public {
        vm.prank(agent1);
        aiAgents.registerAgent("Agent One");

        vm.expectRevert("Agent already registered");
        vm.prank(agent1);
        aiAgents.registerAgent("Agent One Again");
    }

    function testSubmitTask() public {
        vm.prank(agent1);
        aiAgents.registerAgent("Agent One");

        vm.prank(user);
        vm.deal(user, 1 ether);
        vm.prank(user);
        aiAgents.submitTask{value: 1 ether}("Task Description", payable(agent1));

        (string memory description, address agent, uint256 payment, bool isCompleted) = aiAgents.getTask(1);
        assertEq(description, "Task Description");
        assertEq(agent, agent1);
        assertEq(payment, 1 ether);
        assertFalse(isCompleted);
    }

    function testCompleteTask() public {
        vm.prank(agent1);
        aiAgents.registerAgent("Agent One");

        vm.prank(user);
        vm.deal(user, 1 ether);
        vm.prank(user);
        aiAgents.submitTask{value: 1 ether}("Task Description", payable(agent1));

        vm.prank(agent1);
        aiAgents.completeTask(1);

        (, , , bool isCompleted) = aiAgents.getTask(1);
        assertTrue(isCompleted);
    }

    function testOnlyAssignedAgentCanCompleteTask() public {
        vm.prank(agent1);
        aiAgents.registerAgent("Agent One");

        vm.prank(agent2);
        aiAgents.registerAgent("Agent Two");

        vm.prank(user);
        vm.deal(user, 1 ether);
        vm.prank(user);
        aiAgents.submitTask{value: 1 ether}("Task Description", payable(agent1));

        vm.expectRevert("Only the assigned agent can complete this task");
        vm.prank(agent2);
        aiAgents.completeTask(1);
    }
} 