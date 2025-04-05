import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying Whitelister with account:", deployer.address);

  const mailboxAddress = "0xd9Cc2e652A162bb93173d1c44d46cd2c0bbDA59Ds"; // EVM on Flow Mailbox address

  const Whitelister = await ethers.getContractFactory("Whitelister");
  const contract = await Whitelister.deploy(mailboxAddress);

  await contract.waitForDeployment();
  console.log("✅ Whitelister deployed to:", await contract.getAddress());
}

main().catch((error) => {
  console.error("❌ Error deploying Whitelister:", error);
  process.exit(1);
});
