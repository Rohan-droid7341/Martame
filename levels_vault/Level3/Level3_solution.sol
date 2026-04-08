// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WarpGovernance {
    struct Proposal {
        uint256 newSpeed;
        uint256 yesVotes;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    // FIX: Mapping mapped to proposal ID to allow users to vote on multiple isolated proposals
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    uint256 public proposalCount;
    uint256 public warpSpeed;

    function createProposal(uint256 _speed) external {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            newSpeed: _speed,
            yesVotes: 0,
            executed: false
        });
    }

    function vote(uint256 proposalId) external {
        // FIX: Verify against the specific proposal ID
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        
        proposals[proposalId].yesVotes += 1;
        // FIX: Record against the specific proposal ID
        hasVoted[proposalId][msg.sender] = true; 
    }

    function execute(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(!p.executed, "Already executed");
        require(p.yesVotes >= 5, "Not enough votes");

        warpSpeed = p.newSpeed;
        p.executed = true;
    }
}
