// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Level3.sol";

contract WarpGovernanceSecretTest is Test {
    WarpGovernance public gov;

    function setUp() public {
        gov = new WarpGovernance();
    }

    function test_RevertIf_DoubleVoteOnSameProposal() public {
        gov.createProposal(10); // Proposal 1
        
        vm.prank(address(0x1));
        gov.vote(1);

        vm.expectRevert("Already voted");
        vm.prank(address(0x1));
        gov.vote(1); // Should fail!
    }

    function test_AllowsVotingOnDifferentProposals() public {
        gov.createProposal(10); // Proposal 1
        gov.createProposal(20); // Proposal 2

        // User votes on proposal 1
        vm.prank(address(0x1));
        gov.vote(1);

        // Under the BUGGY template, this would revert because hasVoted is global!
        // Under the SECURE fixed template, this will succeed!
        vm.prank(address(0x1));
        gov.vote(2); 

        (, uint256 votes2, ) = gov.proposals(2);
        assertEq(votes2, 1, "User was blocked from voting on Proposal 2!");
    }

    function test_ExecutionFlow() public {
        gov.createProposal(99);
        
        for(uint160 i = 1; i <= 5; i++) {
            vm.prank(address(i));
            gov.vote(1);
        }

        gov.execute(1);
        assertEq(gov.warpSpeed(), 99, "Warp speed did not update");

        vm.expectRevert("Already executed");
        gov.execute(1);
    }
}
