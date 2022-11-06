pragma solidity ^0.8.13;

import { SomeContract } from "@eth-optimism/contracts/SomeContract.sol"; 

struct Call {
    address to;
    bytes data;
}

interface IGovernanceCastVote {
    // interface for uniswap and compound 
    function castVote(uint256 proposalId, uint8 support) external;

    // interface for makerdao 
    function vote(uint256 pollId, uint256 optionId) external; 
}

interface IFooTest {
    function fooBar(uint256 amount, string message) external; 
}

// hyperlane channels 
uint32 constant ETH_GOERLI = 5; 
uint32 constant OPT_GOERLI = 420; 
uint32 constant OPT = 0x6f70; 
uint32 constant ETH = 0x657468; 

// contract addresses 
address constant MAKER = 0xdbE5d00b2D8C13a77Fb03Ee50C87317dbC1B15fb; // goerli testnet 
address constant UNISWAP = 0x408ED6354d4973f66138C91495F2f2FCbd8724C3; // mainnet 
address constant COMPOUND = 0xc0Da02939E1441F497fd74F78cE7Decb17B66529; // mainnet 
address constant TESTCONTRACT = 0xBC3cFeca7Df5A45d61BC60E7898E63670e1654aE; // goerli testnet 

address constant ICAROUTER = 0xffD17672d47E7bB6192d5dBc12A096e00D1a206F; // Hyperlane interchain router 

contract GoatVoter { 
    // assume all proposal ID as uint 

    // verified members of the voting org 
    mapping (address => bool) public members;
    // proposal details 
    struct ProposalDetail {
        // 0 = Uniswap 
        // 1 = Maker poll 
        // 2 = Compound 
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
        else {
            require (proposal.votedMembers[_member] == false, "You cannot double vote!"); 
            proposal.votedMembers[_member] = true; // vote is casted by the member 
        }

        if (_vote) {
            proposal.yea++; 
        } else {
            proposal.nay++;
        }
    }

    ///=== functions for interchain communication ===/// 

    // check the interchain address (proxy account) on ethereum 
    function getInterchainAccount() public view returns (address) {
        address myInterchainAccount = InterchainAccountRouter(ICAROUTER).getInterchainAccount(
            OPT_GOERLI, // TODO: if this should be ETH 
            address(this)
        );
        return myInterchainAccount; 
    }

    // owner only function for the org 
    // function for owner to withdraw fund on the other chain 
    function executeFunction(bytes _date, uint _chainId) public onlyOwner {
        Call[] memory calls = new Call[];
        calls[0] = Call({ to: getInterchainAccount(), data: _date});
        InterchainAccountRouter router = InterchainAccountRouter(ICAROUTER);
        router.getInterchainAccount(OPT_GOERLI, address(this));
        router.dispatch(
            _chainId, 
            calls
        );
    }

    // test only 
    function fooTest() public onlyOwner {
        Call[] memory calls = new Call[];
        calls[0] = Call({
                        to: TESTCONTRACT, 
                        data: abi.encodeCall(IFooTest.fooBar, (2333, "Go bab!"))
                        });
        InterchainAccountRouter router = InterchainAccountRouter(ICAROUTER);
        router.getInterchainAccount(OPT_GOERLI, address(this));
        router.dispatch(
            ETH_GOERLI, 
            calls
        );
    }

    // test only 
    function makerTest() public onlyOwner {
        Call[] memory calls = new Call[];
        calls[0] = Call({
                        to: MAKER, 
                        data: abi.encodeCall(IGovernanceCastVote.vote, (30, 1))
                        });
        InterchainAccountRouter router = InterchainAccountRouter(ICAROUTER);
        router.getInterchainAccount(OPT_GOERLI, address(this));
        router.dispatch(
            ETH_GOERLI, 
            calls
        );
    }

    // cast the vote on Ethereum via Hyperlane 
    // check all proposals due dates and submit the ones due on the date 
    // remove the proposals that are casted 
    // anyone may call the function; Chainlink automation is used 
    function castFinalVote() public { 
        uint today = block.timestamp; 
        uint[] memory proposalsToday = proposalDates[today]; // a list of ID of proposals today 
        Call[] memory calls = new Call[];
        InterchainAccountRouter router = InterchainAccountRouter(ICAROUTER);
        router.getInterchainAccount(OPT_GOERLI, address(this));
        
        for(uint i = 0; i <= proposalsToday.length; i++){
            uint proposalId = proposalsToday[i]; 
            ProposalDetail proposalInfo = proposals[proposalId]; 
            // decide contract based on protocol 

            if (proposal.yea > proposal.nay) {
                // cast a yes vote 
                if (proposalInfo.platform == 0) {
                    // Uniswap 
                    calls[i] = Call({
                        to: UNISWAP, 
                        data: abi.encodeCall(IGovernanceCastVote.castVote, (proposalId, 1))
                        });
                }
                else if (proposalInfo.platform == 1) {
                    // MakerDAO 
                    calls[i] = Call({
                        to: MAKER, 
                        data: abi.encodeCall(IGovernanceCastVote.vote, (proposalId, 1))
                        });
                }
                else if (proposalInfo.platform == 2) {
                    // Compound 
                    calls[i] = Call({
                        to: COMPOUND, 
                        data: abi.encodeCall(IGovernanceCastVote.castVote, (proposalId, 1))
                        });
                }
            } 
            else if (proposal.yea <= proposal.nay) {
                // cast a no vote 
                if (proposal.platform == 0) {
                    // Uniswap 
                    calls[i] = Call({
                        to: UNISWAP, 
                        data: abi.encodeCall(IGovernanceCastVote.castVote, (proposalId, 0))
                        });
                }
                else if (proposal.platform == 1) {
                    // MakerDAO 
                    calls[i] = Call({
                        to: MAKER, 
                        data: abi.encodeCall(IGovernanceCastVote.vote, (proposalId, 0))
                        });
                }
                else if (proposal.platform == 2) {
                    // Compound 
                    calls[i] = Call({
                        to: COMPOUND, 
                        data: abi.encodeCall(IGovernanceCastVote.castVote, (proposalId, 0))
                        });
                }
            }
            delete proposals[proposalId]; // remove the proposal after it is finalized 
        }
        // sending all the voting contract calls together 
        router.dispatch(
            ETH_GOERLI,
            calls
        );
    }
}