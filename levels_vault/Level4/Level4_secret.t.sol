// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Level4.sol";

// Phishing attack to exploit tx.origin
contract Phisher {
    QuantumBridge bridge;

    constructor(QuantumBridge _bridge) {
        bridge = _bridge;
    }

    // Lures the commander into calling this function
    function lure() external {
        bridge.emergencyOverride();
    }

    receive() external payable {}
}

// Contract that rejects ETH to check return values
contract Rejector {
    receive() external payable {
        revert("I refuse cargo");
    }
}

contract QuantumBridgeSecretTest is Test {
    QuantumBridge public bridge;
    Phisher public phisher;
    Rejector public rejector;
    address commander;

    function setUp() public {
        commander = address(0xABC);
        vm.prank(commander);
        bridge = new QuantumBridge();

        phisher = new Phisher(bridge);
        rejector = new Rejector();

        // Load the bridge with funds
        vm.deal(address(0x1), 10 ether);
        vm.prank(address(0x1));
        bridge.loadCargo{value: 10 ether}();
    }

    function test_RevertIf_PhishingAttack() public {
        // Assume the commander was lured into calling the Phisher
        // If the bridge uses msg.sender, the Phisher's call to emergencyOverride will revert
        // because the Phisher (msg.sender) is NOT the commander!
        vm.prank(commander); // tx.origin is commander, but msg.sender to bridge is Phisher
        vm.expectRevert("Unauthorized commander");
        phisher.lure();
    }

    function test_RevertIf_CargoTransferFails() public {
        // A user tries to transfer cargo to a contract that rejects it
        address user = address(0x2);
        vm.deal(user, 1 ether);
        
        vm.startPrank(user);
        bridge.loadCargo{value: 1 ether}();
        
        // If they don't check `success`, this transaction will succeed silently 
        // but the ETH won't move and the user loses their state cargo.
        // The secure implementation MUST revert the entire transaction.
        vm.expectRevert();
        bridge.transferCargo(address(rejector), 1 ether);
        vm.stopPrank();

        // Ensure user still has their cargo in state if it failed
        assertEq(bridge.cargo(user), 1 ether, "Cargo lost due to silent call failure!");
    }

    function test_NormalOverride() public {
        vm.prank(commander);
        bridge.emergencyOverride();

        assertEq(address(bridge).balance, 0);
        assertEq(commander.balance, 10 ether);
    }
}
