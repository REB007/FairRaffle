import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const RaffleManager = await ethers.getContractFactory("RaffleManager");
  // Set the whitelister address; here we're using the deployer's address
  const whitelister = deployer.address;
  const raffleManager = await RaffleManager.deploy(whitelister);

  await raffleManager.deployed();
  console.log("RaffleManager deployed to:", raffleManager.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
