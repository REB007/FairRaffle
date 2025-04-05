import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying Whitelister with account:", deployer.address);

  const Whitelister = await ethers.getContractFactory("Whitelister");
  const contract = await Whitelister.deploy();

  await contract.waitForDeployment();
  console.log("✅ Whitelister deployed to:", await contract.getAddress());
}

main().catch((error) => {
  console.error("❌ Error deploying Whitelister:", error);
  process.exit(1);
});
