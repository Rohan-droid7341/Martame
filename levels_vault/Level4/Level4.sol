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

        // The bridge executes the transfer to the coordinates
        destination.call{value: amount}("");
    }

    function emergencyOverride() external {
        require(tx.origin == bridgeCommander, "Unauthorized commander");
        
        (bool success, ) = bridgeCommander.call{value: address(this).balance}("");
        require(success, "Override failed");
    }
}
