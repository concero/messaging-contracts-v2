import "./utils/configureDotEnv";
import { HardhatUserConfig } from "hardhat/config";

import "@chainlink/hardhat-chainlink";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-network-helpers";
import "@nomicfoundation/hardhat-verify";
import "@nomicfoundation/hardhat-viem";
import "@tenderly/hardhat-tenderly";
import "@typechain/hardhat";
import "hardhat-contract-sizer";
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import "hardhat-gas-reporter";
import "solidity-coverage";

import { conceroNetworks } from "./constants";
import "./tasks";

const enableGasReport = process.env.REPORT_GAS !== "false";

const config: HardhatUserConfig = {
	contractSizer: {
		alphaSort: true,
		runOnCompile: false,
		strict: true,
		disambiguatePaths: false,
	},
	tenderly: {
		username: "Lufaque",
		project: "concero",
		privateVerification: false,
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
					evmVersion: "paris",
					optimizer: {
						enabled: true,
						runs: 200,
					},
				},
			},
			{
				version: "0.8.20",
				settings: {
					viaIR: false,
					evmVersion: "paris",
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
			// arbitrum: process.env.ARBISCAN_API_KEY,
			// arbitrumSepolia: process.env.ARBISCAN_API_KEY,
			// ethereum: process.env.ETHERSCAN_API_KEY,
			// ethereumSepolia: process.env.ETHERSCAN_API_KEY,
			// polygon: process.env.POLYGONSCAN_API_KEY,
			// polygonAmoy: process.env.POLYGONSCAN_API_KEY,
			// optimism: process.env.OPTIMISMSCAN_API_KEY,
			// optimismSepolia: process.env.OPTIMISMSCAN_API_KEY,
			// celo: process.env.CELOSCAN_API_KEY,
			// avalanche: "snowtrace",
			// avalancheFuji: "snowtrace",
		},
	},
	sourcify: {
		enabled: true,
	},
	gasReporter: {
		enabled: enableGasReport,
	},
};

export default config;
