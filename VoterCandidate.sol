// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./VotingSystem.sol";

contract Voter {
    VotingSystem private votingSystem;

    mapping(address => bool) private registeredVoters;
    mapping(address => bool) private voted;
    mapping(address => uint256) private votesReceived;
    

    modifier onlyRegisteredVoter() {
        require(registeredVoters[msg.sender], "You are not a registered voter");
        _;
    }

    modifier electionInProgress() {
        require(votingSystem.electionStarted(), "Election has not started");
        require(!votingSystem.electionEnded(), "Election has already ended");
        _;
    }

    constructor(address _votingSystem) {
        votingSystem = VotingSystem(_votingSystem);
    }

    function registerAsVoter() public {
        registeredVoters[msg.sender] = true;
    }

    function vote(address _candidate) public electionInProgress {
        require(!voted[msg.sender], "You have already voted");
        require(registeredVoters[msg.sender], "You are not registered voter");
        require(votingSystem.isCandidateRegistered(_candidate), "Candidate is not registered");

        voted[msg.sender] = true;
        votesReceived[_candidate]++;
    }

    function viewVoterDetails() public view returns(bool, bool) {
        return (registeredVoters[msg.sender], voted[msg.sender]);
    }

    function getResults(address _candidate) public view returns(uint256) {
        require(votingSystem.electionEnded(), "Election has not ended yet");
        require(votingSystem.isCandidateRegistered(_candidate), "Candidate is not registered");

        return votesReceived[_candidate];
    }

    function viewResultAsCandidate() public view returns(uint256) {
        return getResults(msg.sender);
    }
}
