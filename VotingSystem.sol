// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VotingSystem {
    address private admin;
    bool public electionStarted;
    bool public electionEnded;

    mapping(address => bool) registeredCandidates;
    mapping(address => Candidate) public candidatesDetails;
    address[] private candidateAddresses;
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyRegisteredCandidate() {
        require(registeredCandidates[msg.sender], "You are not a registered candidate");
        _;
    }


    constructor() {
        admin = msg.sender;
    }

    struct Candidate {
        string name;
    }

    function startElection() public onlyAdmin {
        electionStarted = true;
        electionEnded = false;
    }

    function endElection() public onlyAdmin{
        electionEnded = true;
    }

    function registerCandidate(address _candidate, string memory _name) internal {
        registeredCandidates[_candidate] = true;

        candidatesDetails[_candidate] = Candidate({
            name: _name
        });
        candidateAddresses.push(_candidate);
    }

    function isCandidateRegistered(address _candidate) external view returns (bool) {
        return registeredCandidates[_candidate];
    }

    function registerAsCandidate(string memory _name) public {
        registerCandidate(msg.sender, _name);
    }

    function getRegisteredCandidatesCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < candidateAddresses.length; i++) {
            if (registeredCandidates[candidateAddresses[i]]) {
                count++;
            }
        }
        return count;
    }

    function getRegisteredCandidates() external view returns (Candidate[] memory) {
        Candidate[] memory candidates = new Candidate[](candidateAddresses.length);
        for (uint256 i = 0; i < candidateAddresses.length; i++) {
            candidates[i] = candidatesDetails[candidateAddresses[i]];
        }
        return candidates;
    }

}
