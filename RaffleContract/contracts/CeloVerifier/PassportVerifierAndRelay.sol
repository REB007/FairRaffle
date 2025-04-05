// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@selfxyz/contracts/abstract/SelfVerificationRoot.sol";
import "@hyperlane-xyz/core/interfaces/IMailbox.sol";

contract PassportVerifierAndRelay is SelfVerificationRoot {
    IMailbox public mailbox;
    bytes32 public flowReceiver;
    uint32 public flowDomain;
    address public owner;

    event VerifiedAndRelayed(address indexed user);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(
        address _mailbox,
        address _identityVerificationHub,
        address _scope,
        address _attestationId,
        bytes memory _verificationConfig,
        uint32 _flowDomain,
        address _flowReceiver
    )
        SelfVerificationRoot(
            _identityVerificationHub,
            _scope,
            _attestationId,
            _verificationConfig
        )
    {
        mailbox = IMailbox(_mailbox);
        flowDomain = _flowDomain;
        flowReceiver = _addressToBytes32(_flowReceiver);
        owner = msg.sender;
    }

    function setFlowReceiver(uint32 _domain, address _receiver) external onlyOwner {
        flowDomain = _domain;
        flowReceiver = _addressToBytes32(_receiver);
    }

    function _addressToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function verifyPassportAndRelay(bytes calldata proof) external {
        _verifyProof(proof, msg.sender);

        bytes memory message = abi.encode(msg.sender);
        mailbox.dispatch(flowDomain, flowReceiver, message);

        emit VerifiedAndRelayed(msg.sender);
    }
}
