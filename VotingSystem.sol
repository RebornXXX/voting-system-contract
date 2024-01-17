// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VotingSystem {

    address private admin;
    bool private electionStarted;
    bool private electionEnded;
    address[] private candidateAddresses;

    
    mapping(address => bool) private registeredVoters;
    mapping(address => bool) private voted;
    mapping(address => bool) registeredCandidates;
    mapping(address => Candidate) private candidatesDetails;

    constructor() {
        admin = msg.sender;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyRegisteredCandidate() {
        require(registeredCandidates[msg.sender], "You are not a registered candidate");
        _;
    }

    modifier onlyRegisteredVoter() {
        require(registeredVoters[msg.sender], "You are not a registered voter");
        _;
    }

    modifier electionInProgress() {
        require (electionStarted, "Election has not started");
        require(!electionEnded, "Election has already ended");
        _;
    }

    struct Candidate {
        string name;
        string id;
        string proposal;
        uint256 votesReceived;
    }

    function startElection() public onlyAdmin {
        electionStarted = true;
        electionEnded = false;
    }

    function endElection() public onlyAdmin{
        electionEnded = true;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }


    function compareBytes(bytes memory a, bytes memory b) internal pure returns (bool) {
        if (a.length != b.length) {
            return false;
        } else {
            for (uint i = 0; i < a.length; i++) {
                if (a[i] != b[i]) {
                    return false;
                }
            }
            return true;
        }
    }

    function stringToAddress(string memory _input) internal pure returns (address) {
    bytes memory inputBytes = bytes(_input);
    require(inputBytes.length == 42, "Invalid input length");

    uint result = 0;
    uint charValue;

    for (uint i = 2; i < inputBytes.length; i++) {
        uint8 digit = uint8(inputBytes[i]);

        if (digit >= 48 && digit <= 57) {
            charValue = digit - 48;  // '0' to '9'
        } else if (digit >= 65 && digit <= 70) {
            charValue = digit - 55;  // 'A' to 'F'
        } else if (digit >= 97 && digit <= 102) {
            charValue = digit - 87;  // 'a' to 'f'
        } else {
            revert("Invalid character in input");
        }

        result = result * 16 + charValue;
    }

    return (address(uint160(result)));
}


    function createId(string memory _name) internal view returns (string memory) {
        bytes memory nameBytes = bytes(_name);
        bytes1 char1 = nameBytes[0];
        bytes1 char2 = nameBytes[nameBytes.length - 1];
        
        // Combine the first and last characters to create an ID
        bytes memory idBytes = new bytes(2);
        idBytes[0] = char1;
        idBytes[1] = char2;

        uint count = getRegisteredCandidatesCount();

        for (uint i =0; i < count; i++){
            Candidate memory candidate = candidatesDetails[candidateAddresses[i]];
            bytes memory tempNameBytes = bytes(candidate.name);
            bytes memory tempIdBytes = new bytes(2);
            tempIdBytes[0] = tempNameBytes[0];
            tempIdBytes[1] = tempNameBytes[tempNameBytes.length -1];

            if (compareBytes(tempIdBytes, idBytes)) {
                    revert("Choose Different Name...");
                }
        }

        return string(idBytes);
    }

    function registerCandidate(address _candidate, string memory _name, string memory _proposal) internal {
        registeredCandidates[_candidate] = true;

        candidatesDetails[_candidate] = Candidate({
            name: _name,
            id: createId(_name),
            proposal: _proposal,
            votesReceived: 0
        });
        candidateAddresses.push(_candidate);
    }



    function registerAsCandidate(string memory _name, string memory _proposal) public {
        require(!registeredCandidates[msg.sender], "Candidate is alredy registrerd.");
        registerCandidate(msg.sender, _name, _proposal);
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

    function registerAsVoter() public {
        registeredVoters[msg.sender] = true;
    }

    function vote(address _candidate) private electionInProgress {
        require(!voted[msg.sender], "You have already voted");
        require(registeredVoters[msg.sender], "You are not registered voter");
        require(registeredCandidates[_candidate], "Candidate is not registered");

        voted[msg.sender] = true;
        candidatesDetails[_candidate].votesReceived++;
    }

    
    function voteById(string memory _idOrAddress) public electionInProgress {
        if (bytes(_idOrAddress).length == 42) { // Assuming addresses are 42 characters long (including '0x' prefix)
            address candidateAddress = stringToAddress(_idOrAddress);
            vote(candidateAddress);
        } else {
            (address returnAddress, ,) = getCandidateById(_idOrAddress);
            vote(returnAddress);
        }
    } 

    function viewVoterDetails() public view returns(bool Registered, bool Voted) {
        return (registeredVoters[msg.sender], voted[msg.sender]);
    }

    function getCandidateId(uint256 index) internal view returns (string memory) {
        require(index < candidateAddresses.length, "Candidate index out of range");

        Candidate memory candidate = candidatesDetails[candidateAddresses[index]];
        return (candidate.id);
    }

    function getCandidateById(string memory _id) public view returns (address, string memory, uint Votes_Received) {
        uint count = getRegisteredCandidatesCount();

        for (uint i = 0; i < count; i++){

            if (compareStrings(_id, getCandidateId(i))) {
                Candidate memory candidate = candidatesDetails[candidateAddresses[i]];
                return (candidateAddresses[i], candidate.name, candidate.votesReceived);
            } 
        }
        revert("ID not found");
    }

    function AllCandidates() public view returns (string[] memory){
        string[] memory result = new string[](candidateAddresses.length);

        for (uint i = 0; i < candidateAddresses.length; i++) {
            Candidate memory candidate = candidatesDetails[candidateAddresses[i]];
            result[i] = string(abi.encodePacked(" ",candidate.name, " (", candidate.id, ")"));
        }

        return result;
    }


    function Winner() public view returns (string memory) {
        require(electionEnded, "Election in progress...");
        uint256 maxVotes = 0;
        address winningCandidate;
        uint count = 0;

        for (uint256 i = 0; i < candidateAddresses.length; i++) {
            if (candidatesDetails[candidateAddresses[i]].votesReceived > maxVotes) {
                maxVotes = candidatesDetails[candidateAddresses[i]].votesReceived;
                winningCandidate = candidateAddresses[i];
            } else if (candidatesDetails[candidateAddresses[i]].votesReceived == maxVotes) {
               count++;
            }
        }

        if (count >= 1) {
                return("Election Tied...");
            }

        return candidatesDetails[winningCandidate].name;
    }

}
