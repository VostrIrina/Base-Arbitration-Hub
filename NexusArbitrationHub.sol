// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

contract NexusArbitrationHub {
    struct DisputeCase {
        address payable buyer;
        address payable seller;
        address arbiter;
        uint256 lockedAmountWei;
        bool isResolved;
        bytes32 caseEvidenceHash;
    }

    address payable public immutable hubAdmin;
    string public hubDescriptor;
    uint256 public platformFeeBps; // 250 = 2.5%
    uint256 public caseCounter;
    uint256 public accumulatedFees;
    bool public isHubHalted;

    mapping(address => bool) public verifiedArbiters;
    mapping(uint256 => DisputeCase) public disputeCases;

    event ArbiterAdded(address indexed arbiter);
    event CaseCreated(uint256 indexed caseId, address indexed buyer, address indexed seller, uint256 amount);
    event TreasuryDeposited(address indexed funder, uint256 amount);
    event ReservesEmptied(address indexed admin, uint256 amount);
    event FeesGathered(address indexed admin, uint256 amount);
    event HubHaltToggled(bool isHalted);
    event CaseResolved(uint256 indexed caseId, address indexed winner, uint256 payout);
    event ArbiterRevoked(address indexed arbiter);
    event DescriptorUpdated(string newDescriptor);

    modifier onlyAdmin() {
        require(msg.sender == hubAdmin, "NexusArb: Access denied");
        _;
    }

    modifier whenNotHalted() {
        require(!isHubHalted, "NexusArb: Hub is halted");
        _;
    }

    constructor() {
        hubAdmin = payable(msg.sender);
        hubDescriptor = "Nexus Base Arbitration Hub v1";
        platformFeeBps = 250; // 2.5%
        isHubHalted = false;
        verifiedArbiters[msg.sender] = true;
    }

    // 1. addVerifiedArbiter
    function addVerifiedArbiter(address arbiter) external onlyAdmin {
        require(!verifiedArbiters[arbiter], "NexusArb: Already verified");
        verifiedArbiters[arbiter] = true;
        emit ArbiterAdded(arbiter);
    }

    // 2. createDisputeCase
    function createDisputeCase(address seller, address arbiter, bytes32 evidenceHash) external payable whenNotHalted returns (uint256) {
        require(msg.value > 0, "NexusArb: Zero locked amount");
        require(seller != address(0) && arbiter != address(0), "NexusArb: Invalid addresses");
        require(verifiedArbiters[arbiter], "NexusArb: Arbiter not verified");

        caseCounter++;
        disputeCases[caseCounter] = DisputeCase({
            buyer: payable(msg.sender),
            seller: payable(seller),
            arbiter: arbiter,
            lockedAmountWei: msg.value,
            isResolved: false,
            caseEvidenceHash: evidenceHash
        });

        emit CaseCreated(caseCounter, msg.sender, seller, msg.value);
        return caseCounter;
    }

    // 3. depositHubTreasury
    function depositHubTreasury() external payable whenNotHalted {
        require(msg.value > 0, "NexusArb: Zero deposit");
        accumulatedFees += msg.value;
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    // 4. emptyHubReserves
    function emptyHubReserves() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "NexusArb: Zero balance");

        accumulatedFees = 0;
        (bool sent, ) = hubAdmin.call{value: balance}("");
        require(sent, "NexusArb: Sweep failed");

        emit ReservesEmptied(hubAdmin, balance);
    }

    // 5. gatherPlatformFees
    function gatherPlatformFees() external onlyAdmin {
        uint256 amount = accumulatedFees;
        require(amount > 0, "NexusArb: Zero fees");

        accumulatedFees = 0;
        (bool sent, ) = hubAdmin.call{value: amount}("");
        require(sent, "NexusArb: Harvest failed");

        emit FeesGathered(hubAdmin, amount);
    }

    // 6. haltArbitrationHub
    function haltArbitrationHub(bool isHalted) external onlyAdmin {
        isHubHalted = isHalted;
        emit HubHaltToggled(isHalted);
    }

    // 7. resolveDisputeBuyer
    function resolveDisputeBuyer(uint256 caseId) external whenNotHalted {
        DisputeCase storage d = disputeCases[caseId];
        require(caseId > 0 && caseId <= caseCounter, "NexusArb: Invalid ID");
        require(!d.isResolved, "NexusArb: Already resolved");
        require(msg.sender == d.arbiter, "NexusArb: Only assigned arbiter");

        d.isResolved = true;
        uint256 fee = (d.lockedAmountWei * platformFeeBps) / 10000;
        uint256 payout = d.lockedAmountWei - fee;
        accumulatedFees += fee;

        (bool sent, ) = d.buyer.call{value: payout}("");
        require(sent, "NexusArb: Refund to buyer failed");

        emit CaseResolved(caseId, d.buyer, payout);
    }

    // 8. resolveDisputeSeller
    function resolveDisputeSeller(uint256 caseId) external whenNotHalted {
        DisputeCase storage d = disputeCases[caseId];
        require(caseId > 0 && caseId <= caseCounter, "NexusArb: Invalid ID");
        require(!d.isResolved, "NexusArb: Already resolved");
        require(msg.sender == d.arbiter, "NexusArb: Only assigned arbiter");

        d.isResolved = true;
        uint256 fee = (d.lockedAmountWei * platformFeeBps) / 10000;
        uint256 payout = d.lockedAmountWei - fee;
        accumulatedFees += fee;

        (bool sent, ) = d.seller.call{value: payout}("");
        require(sent, "NexusArb: Release to seller failed");

        emit CaseResolved(caseId, d.seller, payout);
    }

    // 9. revokeArbiterStatus
    function revokeArbiterStatus(address arbiter) external onlyAdmin {
        require(verifiedArbiters[arbiter], "NexusArb: Not verified");
        require(arbiter != msg.sender, "NexusArb: Cannot revoke self");
        verifiedArbiters[arbiter] = false;
        emit ArbiterRevoked(arbiter);
    }

    // 10. updateHubDescriptor
    function updateHubDescriptor(string calldata newDescriptor) external onlyAdmin {
        require(bytes(newDescriptor).length > 0, "NexusArb: Empty string");
        hubDescriptor = newDescriptor;
        emit DescriptorUpdated(newDescriptor);
    }
}