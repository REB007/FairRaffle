// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { CadenceRandomConsumer } from "@onflow/flow-sol-utils/src/random/CadenceRandomConsumer.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Minimal interface for our Whitelisted contract.
interface IWhitelister {
    function isWhitelisted(address participant) external view returns (bool);
}

contract RaffleManager is CadenceRandomConsumer, ERC721URIStorage, Ownable {
    uint256 public nextTokenId;
    uint256 public raffleCount;
    IWhitelister public whitelistContract;

    struct Raffle {
        address organizer;
        uint256 maxParticipants;
        uint256 deadline;
        string uri; // NFT metadata URI for minting later
        address[] participants;
        bool triggered;
        address winner;
        bool prizeAwarded;
        uint256 requestId;
    }

    mapping(uint256 => Raffle) private raffles;

    event RaffleCreated(
        uint256 indexed raffleId,
        address indexed organizer,
        uint256 maxParticipants,
        uint256 deadline,
        string uri,
        uint256 requestId
    );
    event Participated(uint256 indexed raffleId, address indexed participant);
    event RaffleTriggered(
        uint256 indexed raffleId,
        address indexed winner,
        uint256 randomIndex,
        uint256 mintedTokenId
    );
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    constructor(address _whitelistContract)
        ERC721("RaffleNFT", "RFT")
        Ownable(_msgSender())
    {
        raffleCount = 0;
        nextTokenId = 0;
        whitelistContract = IWhitelisted(_whitelistContract);
    }

    /**
     * @notice Allows the owner to update ownership.
     */
    function setOwner(address _newOwner) external onlyOwner {
        address previousOwner = owner();
        transferOwnership(_newOwner);
        emit OwnerChanged(previousOwner, _newOwner);
    }

    /**
     * @notice Creates a new raffle.
     * Instead of transferring an NFT, this function stores the URI for the NFT to be minted later.
     * @param _maxParticipants Maximum number of participants allowed.
     * @param _deadline Unix timestamp after which no new participants are accepted.
     * @param _uri Metadata URI for the NFT that will be minted to the winner.
     * @return raffleId The ID of the created raffle.
     */
    function createRaffle(
        uint256 _maxParticipants,
        uint256 _deadline,
        string calldata _uri
    ) external onlyOwner returns (uint256) {
        require(_deadline > block.timestamp, "Deadline must be in the future");
        uint256 raffleId = raffleCount;
        raffleCount++;
        Raffle storage r = raffles[raffleId];
        r.organizer = _msgSender();
        r.maxParticipants = _maxParticipants;
        r.deadline = _deadline;
        r.uri = _uri;
        r.requestId = _requestRandomness();
        emit RaffleCreated(raffleId, _msgSender(), _maxParticipants, _deadline, _uri, r.requestId);
        return raffleId;
    }

    /**
     * @notice Allows a whitelisted user to participate in a raffle.
     */
    function participate(uint256 raffleId) external {
        require(whitelistContract.isWhitelisted(_msgSender()), "Not whitelisted");

        Raffle storage r = raffles[raffleId];
        require(block.timestamp < r.deadline, "Deadline passed");
        require(r.participants.length < r.maxParticipants, "Max participants reached");

        // Prevent duplicate entries.
        for (uint256 i = 0; i < r.participants.length; i++) {
            require(r.participants[i] != _msgSender(), "Already participated");
        }
        r.participants.push(_msgSender());
        emit Participated(raffleId, _msgSender());
    }

    /**
     * @notice Triggers a raffle to pick a winner and mints the NFT to the winner.
     */
    function triggerRaffle(uint256 raffleId) external onlyOwner {
        Raffle storage r = raffles[raffleId];
        require(block.timestamp >= r.deadline, "Deadline not reached");
        require(!r.triggered, "Raffle already triggered");
        require(r.participants.length > 0, "No participants");

        uint256 randomIndex = _fulfillRandomInRange(r.requestId, 0, r.participants.length - 1);
        r.winner = r.participants[randomIndex];
        r.triggered = true;
        r.prizeAwarded = true;

        // Mint the NFT to the winner.
        uint256 tokenId = nextTokenId;
        nextTokenId++;
        _safeMint(r.winner, tokenId);
        _setTokenURI(tokenId, r.uri);

        emit RaffleTriggered(raffleId, r.winner, randomIndex, tokenId);
    }

    /**
     * @notice Returns the list of participants in a raffle.
     */
    function getParticipants(uint256 raffleId) external view returns (address[] memory) {
        require(raffleId < raffleCount, "Raffle does not exist");
        return raffles[raffleId].participants;
    }

    /**
     * @notice Returns details of a raffle.
     */
    function getRaffle(uint256 raffleId)
        external
        view
        returns (
            address organizer,
            uint256 maxParticipants,
            uint256 deadline,
            string memory uri,
            bool triggered,
            address winner,
            bool prizeAwarded,
            uint256 requestId
        )
    {
        require(raffleId < raffleCount, "Raffle does not exist");
        Raffle storage r = raffles[raffleId];
        return (r.organizer, r.maxParticipants, r.deadline, r.uri, r.triggered, r.winner, r.prizeAwarded, r.requestId);
    }
}
