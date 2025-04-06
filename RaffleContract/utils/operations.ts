import { ethers } from "ethers";
import * as fs from "fs";
import * as path from "path";

// Load the ABI from your build output
const raffleAbiPath = path.join(__dirname, "RaffleManager.json");
const raffleAbiJson = JSON.parse(fs.readFileSync(raffleAbiPath, "utf8"));
const raffleAbi = raffleAbiJson.abi;

// Config – update these or set as environment variables.
const RPC_URL = process.env.RPC_URL || "https://alfajores-forno.celo-testnet.org";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "0xYOUR_PRIVATE_KEY";
const RAFFLE_ADDRESS = process.env.RAFFLE_ADDRESS || "0xYourRaffleContractAddress";

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
  const raffleContract = new ethers.Contract(RAFFLE_ADDRESS, raffleAbi, wallet);

  const operation = process.argv[2];

  if (operation === "create") {
    // Example: ts-node raffleOperations.ts create 10 1680000000 "https://example.com/nft.json"
    const maxParticipants = parseInt(process.argv[3]);
    const deadline = parseInt(process.argv[4]); // Unix timestamp (seconds)
    const uri = process.argv[5];
    if (!maxParticipants || !deadline || !uri) {
      console.log("Usage: ts-node raffleOperations.ts create <maxParticipants> <deadline> <uri>");
      return;
    }
    console.log("Creating raffle with maxParticipants:", maxParticipants, "deadline:", deadline, "uri:", uri);
    const tx = await raffleContract.createRaffle(maxParticipants, deadline, uri);
    console.log("Transaction sent. Waiting for confirmation...");
    await tx.wait();
    console.log("Raffle created. Tx hash:", tx.hash);
  } else if (operation === "trigger") {
    // Example: ts-node raffleOperations.ts trigger 0
    const raffleId = parseInt(process.argv[3]);
    if (raffleId === undefined || isNaN(raffleId)) {
      console.log("Usage: ts-node raffleOperations.ts trigger <raffleId>");
      return;
    }
    console.log("Triggering raffle with raffleId:", raffleId);
    const tx = await raffleContract.triggerRaffle(raffleId);
    console.log("Transaction sent. Waiting for confirmation...");
    await tx.wait();
    console.log("Raffle triggered. Tx hash:", tx.hash);
  } else {
    console.log("Invalid operation. Use either 'create' or 'trigger'.");
    console.log("Usage:");
    console.log("  ts-node raffleOperations.ts create <maxParticipants> <deadline> <uri>");
    console.log("  ts-node raffleOperations.ts trigger <raffleId>");
  }
}

main().catch((error) => {
  console.error("Error:", error);
  process.exit(1);
});
