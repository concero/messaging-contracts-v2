import "solidity-coverage";

import "hardhat-contract-sizer";
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import "hardhat-gas-reporter";
import { HardhatUserConfig } from "hardhat/config";

import "@chainlink/hardhat-chainlink";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-ignition-viem";
import "@nomicfoundation/hardhat-network-helpers";
import "@nomicfoundation/hardhat-verify";
import "@nomicfoundation/hardhat-viem";
import "@tenderly/hardhat-tenderly";
import "@typechain/hardhat";

import { conceroNetworks } from "./constants";
import "./tasks";
import "./utils/configureDotEnv";

const enableGasReport = process.env.REPORT_GAS !== "false";

const config: HardhatUserConfig = {
	contractSizer: {
		alphaSort: true,
		runOnCompile: false,
		strict: true,
		disambiguatePaths: false,
	},
	tenderly: {
		username: "olegkron",
		project: "own",
	},
	paths: {
		artifacts: "artifacts",
		cache: "cache",
		sources: "contracts",
		tests: "test",
	},
	solidity: {
		compilers: [
			{
				version: "0.8.28",
				settings: {
					viaIR: false,
					optimizer: {
						enabled: true,
						runs: 200,
					},
				},
			},
		],
	},
	defaultNetwork: "localhost",
	namedAccounts: {
		deployer: {
			default: 0,
		},
		proxyDeployer: {
			default: 1,
		},
	},
	networks: conceroNetworks,
	etherscan: {
		apiKey: {
			arbitrum: process.env.ARBISCAN_API_KEY,
			arbitrumSepolia: process.env.ARBISCAN_API_KEY,
			ethereum: process.env.ETHERSCAN_API_KEY,
			sepolia: process.env.ETHERSCAN_API_KEY,
			polygon: process.env.POLYGONSCAN_API_KEY,
			polygonAmoy: process.env.POLYGONSCAN_API_KEY,
			optimism: process.env.OPTIMISMSCAN_API_KEY,
			optimismSepolia: process.env.OPTIMISMSCAN_API_KEY,
			celo: process.env.CELOSCAN_API_KEY,
			avalanche: "snowtrace",
			avalancheFuji: "snowtrace",
		},
	},
	//     customChains: [
	//         {
	//             network: "celo",
	//             chainId: 42220,
	//             urls: {
	//                 apiURL: "https://api.celoscan.io/api",
	//                 browserURL: "https://celoscan.io/",
	//             },
	//         },
	//         {
	//             network: "optimism",
	//             chainId: 10,
	//             urls: {
	//                 apiURL: "https://api-optimistic.etherscan.io/api",
	//                 browserURL: "https://optimistic.etherscan.io/",
	//             },
	//         },
	//         {
	//             network: "arbitrum",
	//             chainId: conceroNetworks.arbitrum.id,
	//             urls: {
	//                 apiURL: "https://api.arbiscan.io/api",
	//                 browserURL: "https://arbiscan.io/",
	//             },
	//         },
	//         {
	//             network: "avalancheFuji",
	//             chainId: conceroNetworks.avalancheFuji.id,
	//             urls: {
	//                 apiURL: "https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan",
	//                 browserURL: "https://snowtrace.io",
	//             },
	//         },
	//     ],
	// },
	// verify: {
	//   etherscan: {
	//     apiKey: `${etherscanApiKey}`,
	//   },
	// },
	sourcify: {
		enabled: true,
	},
	gasReporter: {
		enabled: enableGasReport,
	},
};

export default config;
