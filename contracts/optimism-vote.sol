pragma solidity ^0.8.13;

import { SomeContract } from "@eth-optimism/contracts/SomeContract.sol";
struct Call {
    address to;
    bytes data;
}

interface UniswapGovernanceVote {
    function castVote(uint256 proposalId, uint8 support) external;
}

contract GoatVoter { 
    // assume all proposal ID as uint 

    // verified members of the voting org 
    mapping (address => bool) public members;
    // proposal details 
    struct ProposalDetail {
        // 0 = Uniswap 
        // 1 = Maker poll 
        // 2 = Aave 
        uint platform; 
        address[] votedMembers; 
        uint yea; 
        uint nay; 
        // uint dueDate;
    }
    // maintain the due dates of the proposals 
    mapping(uint => uint[]) public proposalDates; 
    mapping(uint => ProposalDetail) public proposals; 

    function addMember(address _member) public onlyOwner {
        members[_member] = true;
    }
    function removeMember(address _member) public onlyOwner {
        members[_member] = false;
    }
    function checkMember(address _member) public returns (bool){
        // return true if a member is enabled in the voter org 
        return members[_member];
    }

    function submitMemberVote(uint _proposalId, uint _platform, address _member, bool _vote, uint _duedate) public 
    {
        // first check if the member is enabled in the org 
        require(members[_member], "You're not part of the org to cast vote!"); 
        require(_duedate < block.timestamp, "You are submitting a past proposal"); 
        ProposalDetail storage proposal = votes[proposalId]; 
        if (proposal.votedMembers.length == 0) {
            address[] memory votedMembers = new address[](1);
            votedMembers[0] = _member;
            proposal = ProposalDetail({platform: _platform, votedMembers: votedMembers, yea: 0, nay: 0});
            proposalDates[_duedate].add(_proposalId); 
        }
        if (_vote) {
            proposal.yea++; 
        } else {
            proposal.nay++;
        }
    }

    // owner only function for the org 
    // function for owner to withdraw fund on the other chain 
    function executeFunction(bytes _date, uint _chainId) public onlyOwner {
        Call[] memory calls = new Call[];
        calls[0] = Call({ to: governanceContractOnEth, data: _date});
        InterchainAccountRouter router = InterchainAccountRouter(routerAddress);
        router.getInterchainAccount(420, address(this));
        router.dispatch(
            _chainId, 
            calls
        );
    }

    // cast the vote on Ethereum via Hyperlane 
    // check all proposals due dates and submit the ones due on the date 
    // remove the proposals that are casted 
    // anyone may call the function; Chainlink automation is used 
    function castFinalVote() public 
    { 
        uint today = block.timestamp; 
        uint[] memory proposalsToday = proposalDates[today]; 
        Call[] memory calls = new Call[];
        InterchainAccountRouter router = InterchainAccountRouter(routerAddress);
        router.getInterchainAccount(420, address(this));
        
        for(uint i = 0; i <= proposalsToday.length; i++){
            uint proposalId = proposalsToday[i]; 
            ProposalDetail proposalInfo = proposals[proposalId]; 
            if (proposal.yea > proposal.nay) {
                // cast a yes vote 
                calls[i] = Call({ to: governanceContractOnEth, data: abi.encodeCall(IUniswapGovernance.castVote, proposalId, 1)});
                InterchainAccountRouter router = InterchainAccountRouter(routerAddress);
            } 
            else if (proposal.yea <= proposal.nay) {
                // cast a no vote 
                calls[i] = Call({ to: governanceContractOnEth, data: abi.encodeCall(IUniswapGovernance.castVote, proposalId, 0)});
                InterchainAccountRouter router = InterchainAccountRouter(routerAddress);
            }
            delete proposals[proposalId]; // remove the proposal after it is finalized 
        }
        router.dispatch(
            5,
            calls
        );
    }
}