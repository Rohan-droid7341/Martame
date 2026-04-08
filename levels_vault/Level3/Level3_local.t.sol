// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./Level3.sol";

contract WarpGovernanceLocalTest is Test {
    WarpGovernance public gov;

    function setUp() public {
        gov = new WarpGovernance();
    }

    function test_VoteRegisters() public {
        gov.createProposal(10);
        vm.prank(address(0x1));
        gov.vote(1);
        
        (, uint256 votes, ) = gov.proposals(1);
        assertEq(votes, 1);
    }
}
