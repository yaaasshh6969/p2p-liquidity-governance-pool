 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract P2PLiquidityPoolGovernance {
    address public owner;
    uint public proposalCount;

    struct Proposal {
        uint id;
        string description;
        uint voteYes;
        uint voteNo;
        uint deadline;
        bool executed;
        mapping(address => bool) voted;
    }

    mapping(uint => Proposal) public proposals;
    mapping(address => uint) public liquidityContributions;
    uint public totalLiquidity;

    event ProposalCreated(uint id, string description, uint deadline);
    event Voted(uint proposalId, address voter, bool vote);
    event ProposalExecuted(uint proposalId, bool approved);
    event LiquidityAdded(address provider, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyContributor() {
        require(liquidityContributions[msg.sender] > 0, "Not a contributor");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addLiquidity() external payable {
        require(msg.value > 0, "Must send ETH");
        liquidityContributions[msg.sender] += msg.value;
        totalLiquidity += msg.value;
        emit LiquidityAdded(msg.sender, msg.value);
    }

    function createProposal(string memory _description, uint _durationInMinutes) external onlyContributor {
        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.id = proposalCount;
        p.description = _description;
        p.deadline = block.timestamp + (_durationInMinutes * 1 minutes);
        emit ProposalCreated(p.id, _description, p.deadline);
    }

    function voteOnProposal(uint _proposalId, bool _voteYes) external onlyContributor {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp < p.deadline, "Voting ended");
        require(!p.voted[msg.sender], "Already voted");

        p.voted[msg.sender] = true;
        if (_voteYes) {
            p.voteYes += liquidityContributions[msg.sender];
        } else {
            p.voteNo += liquidityContributions[msg.sender];
        }

        emit Voted(_proposalId, msg.sender, _voteYes);
    }

    function executeProposal(uint _proposalId) external {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp >= p.deadline, "Voting ongoing");
        require(!p.executed, "Already executed");

        p.executed = true;
        bool approved = p.voteYes > p.voteNo;
        emit ProposalExecuted(_proposalId, approved);
    }

    function getProposalVotes(uint _proposalId) external view returns (uint yes, uint no) {
        Proposal storage p = proposals[_proposalId];
        return (p.voteYes, p.voteNo);
    }

    function getLiquidityContribution(address _user) external view returns (uint) {
        return liquidityContributions[_user];
    }
} 

