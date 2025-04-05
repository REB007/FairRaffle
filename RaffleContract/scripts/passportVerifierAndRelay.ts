
  //const mailbox = "0xEf9F292fcEBC3848bF4bB92a96a04F9ECBb78E59"; // Hyperlane Mailbox address on Celo Alfajores

  import { ethers } from "hardhat";

  async function main() {
    const [deployer] = await ethers.getSigners();
  
    const mailbox = "0x571f1435613381208477ac5d6974310d88AC7cB7"; // Hyperlane Mailbox address on Celo
    const identityVerificationHub = "0x77117D60eaB7C044e785D68edB6C7E0e134970Ea"; // Self.xyz Identity Verification Hub address
    const scope = 123456; // Your unique scope value provided by Self.xyz (uint256)
    const attestationId = 7890; // Your attestation ID (uint256)
    
    // Age-related configuration
    const olderThanEnabled = true; // Enable the "older than" check (for age filtering)
    const olderThan = 18; // This may be interpreted by your circuit as "over 18" (adjust per your setup)
  
    // Country and OFAC configuration (adjust if needed)
    const forbiddenCountriesEnabled = false;
    const forbiddenCountriesListPacked: [number, number, number, number] = [0, 0, 0, 0];
    const ofacEnabled: [boolean, boolean, boolean] = [false, false, false];
  
    // Hyperlane configuration for Flow
    //const flowDomain = 4242; // Replace with your actual Flow domain ID (Hyperlane)
    //const flowReceiver = "0xFlowWhitelisterAddress"; // Address of the deployed Whitelister contract on Flow
  
    console.log("Deploying PassportVerifierAndRelay with deployer:", deployer.address);
  
    const PassportVerifierAndRelay = await ethers.getContractFactory("PassportVerifierAndRelay");
    const contract = await PassportVerifierAndRelay.deploy(
      mailbox,
      identityVerificationHub,
      scope,
      attestationId,
      olderThanEnabled,
      olderThan,
      forbiddenCountriesEnabled,
      forbiddenCountriesListPacked,
      ofacEnabled
    );
  
    await contract.waitForDeployment();
    console.log("✅ PassportVerifierAndRelayOver18 deployed to:", await contract.getAddress());
  }
  
  main().catch((error) => {
    console.error("❌ Error deploying PassportVerifierAndRelayOver18:", error);
    process.exit(1);
  });
  