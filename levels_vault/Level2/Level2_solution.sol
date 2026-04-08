// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PlasmaVault {
    mapping(address => uint256) public balances;
    
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");

        // FIX: Checks-Effects-Interactions pattern applied.
        // Balance is zeroed out BEFORE the external call is made!
        balances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}