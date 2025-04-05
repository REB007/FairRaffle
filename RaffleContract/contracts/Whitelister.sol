// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { IMessageRecipient } from "@hyperlane-xyz/core/interfaces/IMessageRecipient.sol";

contract Whitelister is IMessageRecipient {
    address public owner;
    uint32 public trustedOrigin; // Expected domain ID (e.g. Celo)
    bytes32 public trustedSender; // Expected sender address from Celo (as bytes32)

    mapping(address => bool) public whitelisted;

    event WhitelistUpdated(address indexed participant, bool status);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
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

    function _addressToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    /**
     * @notice Handles incoming Hyperlane messages.
     * @dev Verifies the origin and sender, decodes the payload, and whitelists the participant.
     */
    function handle(
        uint32 origin,
        bytes32 sender,
        bytes calldata message
    ) external override {
        require(origin == trustedOrigin, "Invalid origin");
        require(sender == trustedSender, "Invalid sender");

        // Expected message payload is an address to whitelist.
        address participant = abi.decode(message, (address));
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
