// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./Level2.sol";

contract PlasmaVaultLocalTest is Test {
    PlasmaVault public vault;

    function setUp() public {
        vault = new PlasmaVault();
    }

    function test_DepositAndWithdraw() public {
        vault.deposit{value: 1 ether}();
        assertEq(address(vault).balance, 1 ether);
        
        vault.withdraw();
        assertEq(address(vault).balance, 0);
    }
}
