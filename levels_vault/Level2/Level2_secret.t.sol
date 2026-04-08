// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Level2.sol";

// attacker
contract Attacker {
    PlasmaVault vault;
    uint256 public attackCount;

    constructor(PlasmaVault _vault) {
        vault = _vault;
    }

    function attack() external payable {
        vault.deposit{value: msg.value}();
        vault.withdraw();
    }

    receive() external payable {
        if (address(vault).balance >= 1 ether && attackCount < 5) {
            attackCount++;
            (bool success, ) = address(vault).call(abi.encodeWithSignature("withdraw()"));
            require(success, "Reentrancy failed");
        }
    }
}

contract PlasmaVaultSecretTest is Test {
    PlasmaVault public vault;
    Attacker public attacker;

    function setUp() public {
        vault = new PlasmaVault();
        attacker = new Attacker(vault);
        
        vm.deal(address(this), 10 ether);
        vault.deposit{value: 10 ether}();
    }

    function test_RevertIf_ReentrancyAttempted() public {
        vm.deal(address(attacker), 1 ether);
        
        // Attacker will attempt to drain.
        // If the contract is secure, the inner withdraws will revert.
        // Our attacker.receive() requires(success), so the whole transaction will revert!
        vm.expectRevert();
        attacker.attack{value: 1 ether}();
        
        assertEq(address(vault).balance, 10 ether, "Vault was drained! Fix your reentrancy.");
    }

    function test_NormalWithdrawWorks() public {
        vm.deal(address(0xBEEF), 2 ether);
        vm.prank(address(0xBEEF));
        vault.deposit{value: 2 ether}();

        vm.prank(address(0xBEEF));
        vault.withdraw();

        assertEq(address(0xBEEF).balance, 2 ether);
        assertEq(address(vault).balance, 10 ether);
    }
}
