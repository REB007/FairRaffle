// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SelfVerificationRoot} from "@selfxyz/contracts/abstract/SelfVerificationRoot.sol";
import {IVcAndDiscloseCircuitVerifier} from "@selfxyz/contracts/contracts/interfaces/IVcAndDiscloseCircuitVerifier.sol";
import {IIdentityVerificationHubV1} from "@selfxyz/contracts/contracts/interfaces/IIdentityVerificationHubV1.sol";
import {CircuitConstants} from "@selfxyz/contracts/contracts/constants/CircuitConstants.sol";
import {CircuitAttributeHandler} from "@selfxyz/contracts/contracts/libraries/CircuitAttributeHandler.sol";
import {Formatter} from "@selfxyz/contracts/contracts/libraries/Formatter.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMailbox} from "@hyperlane-xyz/core/interfaces/IMailbox.sol";

contract PassportVerifierAndRelay is SelfVerificationRoot, Ownable {
    IMailbox public mailbox;
    bytes32 public flowReceiver;
    uint32 public flowDomain;

    // Mapping to store used nullifiers (to prevent replay attacks)
    mapping(uint256 => bool) public usedNullifiers;

    event VerifiedAndRelayed(address indexed user);

    /**
     * @notice Constructor for PassportVerifierAndRelay.
     *
     * @param _mailbox The Hyperlane Mailbox address on Celo.
     * @param _identityVerificationHub The Self.xyz Identity Verification Hub address.
     * @param _scope The scope for the proof.
     * @param _attestationId The attestation identifier.
     * @param _olderThanEnabled Whether the "older than" check is enabled.
     * @param _olderThan The age threshold (if applicable).
     * @param _forbiddenCountriesEnabled Whether country restrictions are enabled.
     * @param _forbiddenCountriesListPacked A packed list of forbidden countries.
     * @param _ofacEnabled Whether OFAC filtering is enabled.
     * @param _flowDomain The Hyperlane domain ID for Flow.
     * @param _flowReceiver The address of the Whitelister contract on Flow.
     */
    constructor(
        address _mailbox,
        address _identityVerificationHub,
        uint256 _scope,
        uint256 _attestationId,
        bool _olderThanEnabled,
        uint256 _olderThan,
        bool _forbiddenCountriesEnabled,
        uint256[4] memory _forbiddenCountriesListPacked,
        bool[3] memory _ofacEnabled,
        //uint32 _flowDomain,
        //address _flowReceiver
    )
        SelfVerificationRoot(
            _identityVerificationHub,
            _scope,
            _attestationId,
            _olderThanEnabled,
            _olderThan,
            _forbiddenCountriesEnabled,
            _forbiddenCountriesListPacked,
            _ofacEnabled
        )
    {
        mailbox = IMailbox(_mailbox);
        //flowDomain = _flowDomain;
        //flowReceiver = _addressToBytes32(_flowReceiver);
        transferOwnership(msg.sender);
    }

    /**
     * @notice Allows the owner to update the Flow receiver and domain.
     */
    function setFlowReceiver(uint32 _domain, address _receiver) external onlyOwner {
        flowDomain = _domain;
        flowReceiver = _addressToBytes32(_receiver);
    }

    function _addressToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    /**
     * @notice Helper to check if the user is over 18 years old.
     *
     * @param revealedDataPacked The revealed data from the verification result.
     * @return True if the user is at least 18, false otherwise.
     */
    function _isOver18(uint256[3] memory revealedDataPacked) internal view returns (bool) {
        // Convert the revealed field elements to bytes.
        bytes memory dobBytes = Formatter.fieldElementsToBytes(revealedDataPacked);
        // Extract the date of birth string (format assumed to be "DD/MM/YYYY" or similar).
        string memory dob = CircuitAttributeHandler.getDateOfBirth(dobBytes);
        // Convert the date string to a Unix timestamp.
        uint256 dobTimestamp = Formatter.dateToUnixTimestamp(dob);
        // Check that at least 18 years have passed since the date of birth.
        return block.timestamp >= dobTimestamp + 18 years;
    }

    /**
     * @notice Verifies a Self.xyz VcAndDisclose proof ensuring the user is over 18,
     * and dispatches a Hyperlane message to Flow.
     *
     * @param proof The structured VcAndDisclose proof.
     */
    function verifyPassportAndRelay(IVcAndDiscloseCircuitVerifier.VcAndDiscloseProof memory proof) external {
        // Get the nullifier from the proof's public signals to prevent replay.
        uint256 nullifier = proof.pubSignals[CircuitConstants.VC_AND_DISCLOSE_NULLIFIER_INDEX];
        require(!usedNullifiers[nullifier], "Proof already used");

        // Verify the proof by calling the Identity Hub via SelfVerificationRoot.
        IIdentityVerificationHubV1.VcAndDiscloseVerificationResult memory result = _identityVerificationHub.verifyVcAndDisclose(
            IIdentityVerificationHubV1.VcAndDiscloseHubProof({
                olderThanEnabled: _verificationConfig.olderThanEnabled,
                olderThan: _verificationConfig.olderThan,
                forbiddenCountriesEnabled: _verificationConfig.forbiddenCountriesEnabled,
                forbiddenCountriesListPacked: _verificationConfig.forbiddenCountriesListPacked,
                ofacEnabled: _verificationConfig.ofacEnabled,
                vcAndDiscloseProof: proof
            })
        );

        // Ensure the user is over 18 using the revealed date of birth.
        require(_isOver18(result.revealedDataPacked), "User is not over 18");

        // Mark the nullifier as used.
        usedNullifiers[nullifier] = true;

        // Dispatch a Hyperlane message to Flow with the verified user's address.
        bytes memory message = abi.encode(msg.sender);
        mailbox.dispatch(flowDomain, flowReceiver, message);

        emit VerifiedAndRelayed(msg.sender);
    }
}
