// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract CrowdFunding {
    mapping(address => uint256) public contributors;
    address public manager;

    uint256 public target;
    uint256 public deadline;
    uint256 public minContri;

    uint256 public raisedAmount;
    uint256 public noOfContributors;

    struct Request {
        string description;
        address payable recipient;
        uint256 value;
        bool completed;
        uint256 noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint256 => Request) public requests;
    uint256 public numRequests;

    constructor(uint256 _target, uint256 _deadline, uint256 _minContri) {
        target = _target;
        deadline = block.timestamp + _deadline;
        minContri = _minContri;
        manager = msg.sender;
    }

    function contribute() public payable {
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value >= minContri, "Min Contribution is not met");

        if (contributors[msg.sender] == 0) {
            noOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function refund() public payable {
        require(
            block.timestamp > deadline && raisedAmount < target,
            "You are not eligible for refund"
        );
        require(contributors[msg.sender] > 0);

        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);

        contributors[msg.sender] = 0;
    }

    function ContractBalence() public view returns (uint256) {
        return address(this).balance;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }

    function createRequests(
        string memory _description,
        address payable _recipient,
        uint256 _value
    ) public onlyManager {
        Request storage newRequest = requests[numRequests];

        numRequests++;

        newRequest.description = _description;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
        newRequest.recipient = _recipient;
    }

    function castVote(uint256 _requestNo) public {
        require(
            contributors[msg.sender] > 0,
            "You must be a contributor first"
        );

        Request storage thisRequest = requests[_requestNo];

        require(
            thisRequest.voters[msg.sender] == false,
            "You have already voted"
        );

        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function sendMoney(uint256 _requestNo) public payable onlyManager {
        require(raisedAmount >= target);

        Request storage thisRequest = requests[_requestNo];
        require(
            thisRequest.completed == false,
            "The request has been completed"
        );
        require(
            thisRequest.noOfVoters > noOfContributors / 2,
            "Majority does not support"
        );
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}
