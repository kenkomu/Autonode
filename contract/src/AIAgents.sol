// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AIAgents {
    struct Agent {
        string name;
        bool isActive;
    }

    struct Task {
        string description;
        address payable agent;
        uint256 payment;
        bool isCompleted;
    }

    mapping(address => Agent) public agents;
    mapping(uint256 => Task) public tasks;
    uint256 public taskCount;

    event AgentRegistered(address indexed agentAddress, string name);
    event TaskSubmitted(uint256 indexed taskId, address indexed agent, string description, uint256 payment);
    event TaskCompleted(uint256 indexed taskId, address indexed agent);

    modifier onlyActiveAgent() {
        require(agents[msg.sender].isActive, "Only active agents can perform this action");
        _;
    }

    modifier onlyAssignedAgent(uint256 taskId) {
        require(tasks[taskId].agent == msg.sender, "Only the assigned agent can complete this task");
        _;
    }

    function registerAgent(string memory _name) external {
        require(bytes(agents[msg.sender].name).length == 0, "Agent already registered");
        agents[msg.sender] = Agent(_name, true);
        emit AgentRegistered(msg.sender, _name);
    }

    function submitTask(string memory _description, address payable _agent) external payable {
        require(msg.value > 0, "Payment must be greater than zero");
        require(agents[_agent].isActive, "Agent must be active");

        taskCount++;
        tasks[taskCount] = Task(_description, _agent, msg.value, false);
        emit TaskSubmitted(taskCount, _agent, _description, msg.value);
    }

    function completeTask(uint256 _taskId) external onlyActiveAgent onlyAssignedAgent(_taskId) {
        Task storage task = tasks[_taskId];
        require(!task.isCompleted, "Task already completed");

        task.isCompleted = true;
        task.agent.transfer(task.payment);
        emit TaskCompleted(_taskId, msg.sender);
    }

    function getAgent(address _agent) external view returns (string memory, bool) {
        Agent memory agent = agents[_agent];
        return (agent.name, agent.isActive);
    }

    function getTask(uint256 _taskId) external view returns (string memory, address, uint256, bool) {
        Task memory task = tasks[_taskId];
        return (task.description, task.agent, task.payment, task.isCompleted);
    }
}