import { type EnvCLCCIP } from "./env.clccip";
import { type EnvCLA } from "./env.cla";
import { type EnvCLF } from "./env.clf";
import { EnvTokens } from "./env.tokens";

export interface env extends EnvCLA, EnvCLF, EnvCLCCIP, EnvTokens {
    // .env.wallets
    TESTNET_PROXY_DEPLOYER_ADDRESS: string;
    TESTNET_PROXY_DEPLOYER_PRIVATE_KEY: string;
    TESTNET_DEPLOYER_ADDRESS: string;
    TESTNET_DEPLOYER_PRIVATE_KEY: string;
    LOCALHOST_PROXY_DEPLOYER_ADDRESS: string;
    LOCALHOST_PROXY_DEPLOYER_PRIVATE_KEY: string;
    LOCALHOST_DEPLOYER_ADDRESS: string;
    LOCALHOST_DEPLOYER_PRIVATE_KEY: string;
    MAINNET_PROXY_DEPLOYER_ADDRESS: string;
    MAINNET_PROXY_DEPLOYER_PRIVATE_KEY: string;
    MAINNET_DEPLOYER_ADDRESS: string;
    MAINNET_DEPLOYER_PRIVATE_KEY: string;
    MESSENGER_PRIVATE_KEY: string;
    MESSENGER_0_ADDRESS: string;
    MESSENGER_1_ADDRESS: string;
    MESSENGER_2_ADDRESS: string;
    MESSENGER_0_PRIVATE_KEY: string;
    MESSENGER_1_PRIVATE_KEY: string;
    MESSENGER_2_PRIVATE_KEY: string;

    // .env
    ETHEREUM_FORKING_ENABLED: string;
    TENDERLY_AUTOMATIC_VERIFICATION: string;
    INFURA_API_KEY: string;
    ALCHEMY_API_KEY: string;
    ETHERSCAN_API_KEY: string;
    BASESCAN_API_KEY: string;
    ARBISCAN_API_KEY: string;
    POLYGONSCAN_API_KEY: string;
    OPTIMISMSCAN_API_KEY: string;
    CELOSCAN_API_KEY: string;
    BLAST_API_KEY: string;
    TENDERLY_API_KEY: string;
    CHAINSTACK_API_KEY: string;
    CONCERO_BRIDGE_SEPOLIA: string;
    CONCERO_BRIDGE_ARBITRUM_SEPOLIA: string;
    CONCERO_BRIDGE_BASE_SEPOLIA: string;
    CONCERO_BRIDGE_FUJI: string;
    CONCERO_BRIDGE_OPTIMISM_SEPOLIA: string;
    LOCALHOST_RPC_URL: string;
    HARDHAT_RPC_URL: string;
}

export default env;
