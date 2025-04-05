// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import {CadenceRandomConsumer} from "@onflow/flow-sol-utils/src/random/CadenceRandomConsumer.sol";

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract RaffleManager is CadenceRandomConsumer {
    address public owner;
    address public whitelister;
    uint256 public raffleCount;
    mapping(address => bool) public whitelisted;

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event WhitelisterChanged(address indexed oldWhitelister, address indexed newWhitelister);
    event WhitelistUpdated(address indexed participant, bool status);
    event RaffleCreated(
        uint256 indexed raffleId,
        address indexed organizer,
        uint256 maxParticipants,
        uint256 deadline,
        address nftAddress,
        uint256 tokenId,
        uint256 requestId
    );
    event Participated(uint256 indexed raffleId, address indexed participant);
    event RaffleTriggered(uint256 indexed raffleId, address indexed winner, uint256 randomIndex);

    struct Raffle {
        address organizer;
        uint256 maxParticipants;
        uint256 deadline;
        address nftAddress;
        uint256 tokenId;
        address[] participants;
        bool triggered;
        address winner;
        bool prizeAwarded;
        uint256 requestId;
    }

    mapping(uint256 => Raffle) private raffles;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier raffleExists(uint256 raffleId) {
        require(raffleId < raffleCount, "Raffle does not exist");
        _;
    }

    constructor(address _whitelister) {
        owner = msg.sender;
        whitelister = _whitelister;
        raffleCount = 0;
    }

    function setWhitelister(address _whitelister) external onlyOwner {
        emit WhitelisterChanged(whitelister, _whitelister);
        whitelister = _whitelister;
    }

    function setOwner(address _owner) external onlyOwner {
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    function setWhitelisted(address participant, bool status) external {
        require(msg.sender == whitelister, "Not whitelister");
        whitelisted[participant] = status;
        emit WhitelistUpdated(participant, status);
    }

    function isWhitelisted(address participant) external view returns (bool) {
        return whitelisted[participant];
    }

    function addWhitelist(address participant) external onlyOwner {
        whitelisted[participant] = true;
        emit WhitelistUpdated(participant, true);
    }

    function createRaffle(
        uint256 _maxParticipants,
        uint256 _deadline,
        address _nftAddress,
        uint256 _tokenId
    ) external onlyOwner returns (uint256) {
        require(_deadline > block.timestamp, "Deadline must be in the future");
        uint256 raffleId = raffleCount;
        raffleCount++;
        Raffle storage r = raffles[raffleId];
        r.organizer = msg.sender;
        r.maxParticipants = _maxParticipants;
        r.deadline = _deadline;
        r.nftAddress = _nftAddress;
        r.tokenId = _tokenId;
        r.requestId = _requestRandomness();
        IERC721(_nftAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
        emit RaffleCreated(raffleId, msg.sender, _maxParticipants, _deadline, _nftAddress, _tokenId, r.requestId);
        return raffleId;
    }

    function participate(uint256 raffleId) external raffleExists(raffleId) {
        require(whitelisted[msg.sender], "Not whitelisted");
        Raffle storage r = raffles[raffleId];
        require(block.timestamp < r.deadline, "Deadline passed");
        require(r.participants.length < r.maxParticipants, "Max participants reached");
        for (uint256 i = 0; i < r.participants.length; i++) {
            require(r.participants[i] != msg.sender, "Already participated");
        }
        r.participants.push(msg.sender);
        emit Participated(raffleId, msg.sender);
    }

    function triggerRaffle(uint256 raffleId) external onlyOwner raffleExists(raffleId) {
        Raffle storage r = raffles[raffleId];
        require(block.timestamp >= r.deadline, "Deadline not reached");
        require(!r.triggered, "Raffle already triggered");
        require(r.participants.length > 0, "No participants");
        uint256 randomIndex = _fulfillRandomInRange(r.requestId, uint64(0), uint64(r.participants.length - 1));
        r.winner = r.participants[randomIndex];
        r.triggered = true;
        r.prizeAwarded = true;
        IERC721(r.nftAddress).safeTransferFrom(address(this), r.winner, r.tokenId);
        emit RaffleTriggered(raffleId, r.winner, randomIndex);
    }

    function getParticipants(uint256 raffleId) external view raffleExists(raffleId) returns (address[] memory) {
        return raffles[raffleId].participants;
    }

    function getRaffle(uint256 raffleId)
        external
        view
        raffleExists(raffleId)
        returns (
            address organizer,
            uint256 maxParticipants,
            uint256 deadline,
            address nftAddress,
            uint256 tokenId,
            bool triggered,
            address winner,
            bool prizeAwarded,
            uint256 requestId
        )
    {
        Raffle storage r = raffles[raffleId];
        return (r.organizer, r.maxParticipants, r.deadline, r.nftAddress, r.tokenId, r.triggered, r.winner, r.prizeAwarded, r.requestId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
