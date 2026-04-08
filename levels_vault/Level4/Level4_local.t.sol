// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./Level4.sol";

contract QuantumBridgeLocalTest is Test {
    QuantumBridge public bridge;

    function setUp() public {
        bridge = new QuantumBridge();
    }

    function test_LoadAndTransfer() public {
        bridge.loadCargo{value: 1 ether}();
        assertEq(bridge.cargo(address(this)), 1 ether);
        
        bridge.transferCargo(address(0x123), 1 ether);
        assertEq(address(0x123).balance, 1 ether);
        assertEq(bridge.cargo(address(this)), 0);
    }
}
