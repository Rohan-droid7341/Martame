// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract QuantumBridge {
    address public bridgeCommander;
    mapping(address => uint256) public cargo;

    constructor() {
        bridgeCommander = msg.sender;
    }

    function loadCargo() external payable {
        cargo[msg.sender] += msg.value;
    }

    function transferCargo(address destination, uint256 amount) external {
        require(cargo[msg.sender] >= amount, "Insufficient cargo");
        cargo[msg.sender] -= amount;

        // FIX: Always handle low-level call return values
        (bool success, ) = destination.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function emergencyOverride() external {
        // FIX: Replaced dangerous tx.origin with secure msg.sender
        require(msg.sender == bridgeCommander, "Unauthorized commander");
        
        (bool success, ) = bridgeCommander.call{value: address(this).balance}("");
        require(success, "Override failed");
    }
}
