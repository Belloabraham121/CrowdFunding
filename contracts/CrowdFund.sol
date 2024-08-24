// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CrowdFunding {

    // The Campaign struct represents each crowdfunding campaign
    struct Campaign {
        string title; // Title of the campaign
        string description; // Description of the campaign
        address payable benefactor; // Address of the person who will receive the funds if the campaign is successful
        uint goal; // Funding goal of the campaign (in wei)
        uint deadline; // Deadline for the campaign (in UNIX timestamp)
        uint amountRaised; // The total amount raised so far for this campaign
        bool ended; // A boolean flag to indicate whether the campaign has ended
    }

    // State variables
    address public owner; // Address of the contract owner, who deployed the contract
    uint public campaignCount; // Count of the total number of campaigns created
    mapping(uint => Campaign) public campaigns; // Mapping to store campaigns with a unique ID for each

    // Events are emitted when certain actions occur, allowing off-chain applications to listen and respond
    event CampaignCreated(
        uint campaignId, // Unique ID of the campaign
        string title, // Title of the campaign
        string description, // Description of the campaign
        address benefactor, // Address of the benefactor who will receive the funds
        uint goal, // Funding goal of the campaign
        uint deadline // Deadline for the campaign
    );

    event DonationReceived(
        uint campaignId, // Unique ID of the campaign
        string title, // Title of the campaign
        address donor, // Address of the donor
        uint amount // Amount donated (in wei)
    );

    event CampaignEnded(
        uint campaignId, // Unique ID of the campaign
        uint amountRaised, // Total amount raised by the campaign
        address benefactor // Address of the benefactor who received the funds
    );

    // Modifier to check if the current time is before the campaign's deadline
    modifier BeforeDeadline(uint campaignId) {
        require(block.timestamp < campaigns[campaignId].deadline, "The campaign deadline has passed");
        _;
    }
    
    // Modifier to restrict function access to only the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    // Modifier to restrict function access to only the benefactor of the campaign
    modifier onlyBenefactor(uint campaignId) {
        require(msg.sender == campaigns[campaignId].benefactor, "Only the benefactor can end the campaign");
        _;
    }
    
    // Modifier to check if the current time is after the campaign's deadline
    modifier AfterDeadline(uint campaignId) {
        require(block.timestamp >= campaigns[campaignId].deadline, "The campaign deadline has not passed yet");
        _;
    }

    // Constructor that initializes the contract owner to the address that deploys the contract
    constructor() {
        owner = msg.sender;
    }

    // Function to create a new campaign
    function createCampaign(
        string memory _title,
        string memory _description,
        address payable _benefactor,
        uint _goal,
        uint _durationInMinutes
    ) public {
        // Ensure the campaign goal is greater than zero
        require(_goal > 0, "Goal must be greater than zero");

        // Increment the campaign count to assign a unique ID to the new campaign
        campaignCount++;
        
        // Calculate the campaign deadline in seconds
        uint durationInSeconds = _durationInMinutes * 60;
        uint deadline = block.timestamp + durationInSeconds;

        // Store the new campaign in the mapping
        campaigns[campaignCount] = Campaign({
            title: _title,
            description: _description,
            benefactor: _benefactor,
            goal: _goal,
            deadline: deadline,
            amountRaised: 0,
            ended: false
        });

        // Emit an event to signal that a new campaign has been created
        emit CampaignCreated(campaignCount, _title, _description, _benefactor, _goal, deadline);
    }

    // Function to allow users to donate to a campaign
    function donateToCampaign(string memory _title, uint _campaignId) public payable BeforeDeadline(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        
        // Ensure the campaign has not ended
        require(!campaign.ended, "The campaign has ended");

        // Increment the amount raised by the campaign by the value of the donation
        campaign.amountRaised += msg.value;

        // Emit an event to signal that a donation has been received
        emit DonationReceived(_campaignId, _title, msg.sender, msg.value);
    }

    // Function to end a campaign and transfer the funds to the benefactor
    function endCampaign(uint _campaignId) public onlyBenefactor(_campaignId) AfterDeadline(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        
        // Ensure the campaign has not already been ended
        require(!campaign.ended, "Campaign has ended");

        // Mark the campaign as ended
        campaign.ended = true;

        // Transfer the amount raised to the benefactor
        campaign.benefactor.transfer(campaign.amountRaised);

        // Emit an event to signal that the campaign has ended and the funds have been transferred
        emit CampaignEnded(_campaignId, campaign.amountRaised, campaign.benefactor);
    }

    // Function to allow the owner to withdraw any leftover funds in the contract
    function withdrawFunds() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

}
