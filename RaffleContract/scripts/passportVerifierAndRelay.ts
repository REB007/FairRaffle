import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  // TODO: Replace these placeholder values with your actual contract parameters.
  const mailbox = "0xYourCeloMailboxAddress"; // Hyperlane Mailbox address on Celo
  const identityHub = "0xSelfIdentityHubAddress"; // Self.xyz Identity Verification Hub address
  const scope = "0xScopeAddress"; // Self.xyz scope address
  const attestationId = "0xAttestationId"; // Self.xyz attestation ID
  const verificationConfig = "0x"; // Verification config (often an empty bytes string)
  const flowDomain = 4242; // Replace with your actual Flow domain ID (Hyperlane)
  const flowReceiver = "0xFlowWhitelisterAddress"; // Deployed Whitelister contract address on Flow

  console.log("Deploying PassportVerifierAndRelay with account:", deployer.address);

  const PassportVerifierAndRelay = await ethers.getContractFactory("PassportVerifierAndRelay");
  const contract = await PassportVerifierAndRelay.deploy(
    mailbox,
    identityHub,
    scope,
    attestationId,
    verificationConfig,
    flowDomain,
    flowReceiver
  );

  await contract.waitForDeployment();
  console.log("✅ PassportVerifierAndRelay deployed to:", await contract.getAddress());
}

main().catch((error) => {
  console.error("❌ Error deploying PassportVerifierAndRelay:", error);
  process.exit(1);
});
