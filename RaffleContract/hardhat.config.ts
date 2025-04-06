import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

const FLOW_TESTNET_RPC_URL = process.env.FLOW_TESTNET_RPC_URL || "";
const FLOW_MAINNET_RPC_URL = process.env.FLOW_MAINNET_RPC_URL || "";
const FLOW_TESTNET_CHAIN_ID = process.env.FLOW_TESTNET_CHAIN_ID || "0";
const FLOW_MAINNET_CHAIN_ID = process.env.FLOW_MAINNET_CHAIN_ID || "0";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

const config: HardhatUserConfig = {
  solidity: "0.8.19",
  networks: {
    flowTestnet: {
      url: FLOW_TESTNET_RPC_URL,
      chainId: parseInt(FLOW_TESTNET_CHAIN_ID),
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    flowMainnet: {
      url: FLOW_MAINNET_RPC_URL,
      chainId: parseInt(FLOW_MAINNET_CHAIN_ID),
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    celo:{
      url: "https://alfajores-forno.celo-testnet.org",
      chainId: 44787,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    }
  },
};

export default config;
