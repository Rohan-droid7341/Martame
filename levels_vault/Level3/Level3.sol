// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WarpGovernance {
    struct Proposal {
        uint256 newSpeed;
        uint256 yesVotes;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public hasVoted; // Check this variable

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
        require(!hasVoted[msg.sender], "Already voted");
        
        proposals[proposalId].yesVotes += 1;
        hasVoted[msg.sender] = true; 
    }

    function execute(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        require(!p.executed, "Already executed");
        require(p.yesVotes >= 5, "Not enough votes");

        warpSpeed = p.newSpeed;
        p.executed = true;
    }
}
