import axios from 'axios';
import { useContractRead } from 'wagmi'
import contractAbi from '../resources/abi.json'
export async function getMaker() {

    let makerProposals = []
    const poll_response = await axios.get('https://vote.makerdao.com/api/polling/all-polls',
        {
            headers: {
                'Content-Type': 'application/json'
            }
        });
    var allProposals = poll_response.data.polls;

    for (var i in allProposals) {
        var proposal = allProposals[i];

        var title = proposal.title;
        var id = proposal.pollId;
        var platform = "Maker";
        var pollForum = proposal.discussionLink
        var endDate = new Date(proposal.endDate);
        var currDate = new Date();
        var state = (endDate < currDate) ? "active" : "past";
        // clear out proposals that were started more than 2 weeks ago
        var startDate = new Date(proposal.startDate);
        startDate.setDate(startDate.getDate() + 14);

        if (state != "active" || startDate < currDate) break;
        var link = proposal.url;
        var endBlock = parseInt(proposal.blockCreated); //TODO

        var proposalJSON = {
            title: title,
            id: id,
            platform: platform,
            state: state,
            linkMKR: link,
            endBlock: null,
            startDate: proposal.startDate,
            endDate: endDate,
            link: pollForum
        }
        makerProposals.push(proposalJSON);
    }
    let testProp = {
            title: "Test Proposal!",
            id: 30,
            platform: "Maker",
            state: "active",
            linkMKR: "",
            endBlock: null,
            startDate: new Date(2022, 11, 1),
            endDate: new Date(2022, 11, 10),
            link: ""
    }
    makerProposals.push(testProp)
    return makerProposals
}

export async function getCompound() {
    var query = `{
        proposals(orderBy: endBlock, orderDirection: desc) {
        id
        status
        endBlock
        description
        }
    }`;
    const response = await axios.post('https://api.compound.finance/api/v2/governance/proposals', {
        query: query
    },
        {
            headers: {
                'Content-Type': 'application/json'
            }
        });
    // console.log(response.data.proposals)
    // console.log(response.data.proposals[0].states)
    var allProposals = response.data.proposals
    var compoundProposals = [];

    for (var i = 0; i < allProposals.length; i++) {
        var proposal = allProposals[i];
        // console.log(proposal)
        // Get most recent state update
        var most_recent_state = proposal.states[proposal.states.length - 1];

        // console.log(most_recent_state.end_time)
        // var startTime = parseInt(most_recent_state.start_time);
        var endTime = most_recent_state.end_time;
        var startTime = most_recent_state.start_time;

        if (endTime == null) {
            // console.log(startTime)
            break;
        }
        let endDate = new Date(endTime * 1000)
        let startDate = new Date(startTime * 1000)
        var id = proposal.id;
        var platform = "Compound";
        var state = most_recent_state.state;

        var title = proposal.title;


        var link = "https://compound.finance/governance/proposals/" + id;
        var proposalJSON = {
            title: title,
            id: id,
            platform: platform,
            state: state.toLowerCase(),
            link: link,
            endDate: endDate,
            startDate: startDate,

            // TODO: Compound API does not have endBlock, add endBlock back into response
            endBlock: null
        }
        compoundProposals.push(proposalJSON);
    }
    return compoundProposals;
}

export async function getAll() {
    let promises = [];
    promises.push(getCompound())
    promises.push(getMaker())

    Promise.all(promises).then(([a, b]) => {
        return [a,b]
    });
}