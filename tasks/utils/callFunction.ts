import { task } from "hardhat/config";
import { type Address } from "viem";

import { conceroNetworks } from "../../constants";
import { getFallbackClients } from "../../utils";
import log from "../../utils/log";

export async function callContractFunction(targetContract: Address) {
	const chain = conceroNetworks.base;

	const { walletClient, publicClient, account } = getFallbackClients(chain);
	const gasPrice = await publicClient.getGasPrice();

	const { request: sendReq } = await publicClient.simulateContract({
		functionName: "clearDepositsOnTheWay",
		abi: [
			{
				inputs: [],
				stateMutability: "nonpayable",
				type: "function",
				name: "clearDepositsOnTheWay",
				outputs: [],
			},
		],
		account,
		address: targetContract,
		args: [],
		gasPrice,
	});

	const sendHash = await walletClient.writeContract(sendReq);
	const { cumulativeGasUsed: sendGasUsed } = await publicClient.waitForTransactionReceipt({
		hash: sendHash,
	});
	log(
		`Called Contract ${targetContract} : ${sendHash} Gas used: ${sendGasUsed}`,
		"callContractFunction",
		chain.name,
	);
}

task(
	"call-contract-function",
	"Calls a specific contract function. Use for testing and maintenance",
).setAction(async (taskArgs, hre) => {
	await callContractFunction(taskArgs.contract);
});
