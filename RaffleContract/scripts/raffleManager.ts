import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  // TODO: Replace this with the actual deployed Whitelister contract address on Flow.
  const whitelisterAddress = "0xDeployedWhitelisterAddress";

  console.log("Deploying RaffleManager with account:", deployer.address);

  const RaffleManager = await ethers.getContractFactory("RaffleManager");
  const contract = await RaffleManager.deploy(whitelisterAddress);

  await contract.waitForDeployment();
  console.log("✅ RaffleManager deployed to:", await contract.getAddress());
}

main().catch((error) => {
  console.error("❌ Error deploying RaffleManager:", error);
  process.exit(1);
});
