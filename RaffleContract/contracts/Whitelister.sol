// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IMessageRecipient } from "@hyperlane-xyz/core/interfaces/IMessageRecipient.sol";

contract Whitelister is IMessageRecipient {
    address public owner;
    address public mailbox; // The Hyperlane Mailbox on this chain
    uint32 public trustedOrigin; // Expected domain ID (e.g. Celo)
    bytes32 public trustedSender; // Expected sender address from Celo (as bytes32)

    mapping(address => bool) public whitelisted;

    event WhitelistUpdated(address indexed participant, bool status);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _mailbox) {
        owner = msg.sender;
        mailbox = _mailbox;
    }

    /**
     * @notice Sets the trusted Hyperlane sender details.
     * @param _trustedOrigin The domain ID of the Celo chain.
     * @param _trustedSender The address of the trusted Celo contract.
     */
    function setTrustedHyperlaneSender(uint32 _trustedOrigin, address _trustedSender) external onlyOwner {
        trustedOrigin = _trustedOrigin;
        trustedSender = _addressToBytes32(_trustedSender);
    }

    /**
     * @notice Internal helper to convert an address to bytes32.
     */
    function _addressToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    /**
     * @notice Handles incoming Hyperlane messages.
     * @dev Only the configured Hyperlane Mailbox can call this function.
     * Verifies the message's origin and sender, decodes the payload, and whitelists the participant.
     */
    function handle(
        uint32 origin,
        bytes32 sender,
        bytes calldata message
    ) external override {
        // Ensure that only the Hyperlane Mailbox calls this function.
        require(msg.sender == mailbox, "Only mailbox can call");
        require(origin == trustedOrigin, "Invalid origin");
        require(sender == trustedSender, "Invalid sender");
        
        // Optionally, enforce expected payload length (should be 32 bytes for an address)
        require(message.length == 32, "Invalid message payload length");
        
        // Decode the address from the payload
        address participant = abi.decode(message, (address));
        
        // Whitelist the participant
        whitelisted[participant] = true;
        emit WhitelistUpdated(participant, true);
    }

    /**
     * @notice Allows the owner to manually update a participant's whitelist status.
     */
    function setWhitelisted(address participant, bool status) external onlyOwner {
        whitelisted[participant] = status;
        emit WhitelistUpdated(participant, status);
    }

    /**
     * @notice Checks if a participant is whitelisted.
     */
    function isWhitelisted(address participant) external view returns (bool) {
        return whitelisted[participant];
    }
}
