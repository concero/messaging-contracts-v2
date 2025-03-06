import { parseEther } from "viem";

const messengerTargetBalances: Record<string, bigint> = {
	ethereum: parseEther("0.01"),
	arbitrum: parseEther("0.01"),
	polygon: parseEther("0.1"),
	avalanche: parseEther("0.01"),
	base: parseEther("0.01"),
};

const deployerTargetBalances: Record<string, bigint> = {
	ethereum: parseEther("0.01"),
	arbitrum: parseEther("0.01"),
	polygon: parseEther("1"),
	avalanche: parseEther("0.3"),
	base: parseEther("0.01"),
	//testnet
	sepolia: parseEther("0.1"),
	arbitrumSepolia: parseEther("0.01"),
	polygonAmoy: parseEther("0.01"),
	avalancheFuji: parseEther("0.3"),
	baseSepolia: parseEther("0.01"),
};

export { messengerTargetBalances, deployerTargetBalances };
