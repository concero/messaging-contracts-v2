import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Address, Hash } from "viem";

import { log } from "../../utils";

export const ethersSignerCallContract = async (
	hre: HardhatRuntimeEnvironment,
	contract: Address,
	abi: any[],
	functionName: string,
	...functionArgs: any[]
) => {
	const [ethersSigner] = await hre.ethers.getSigners();
	const ethersContract = new hre.ethers.Contract(contract, abi, ethersSigner);
	const unsignedTx = await ethersContract[functionName].populateTransaction(...functionArgs);

	log(
		`Size: ${(unsignedTx.data.length - 2) / 2}, Input data: ${unsignedTx.data}, Address: ${unsignedTx.to}`,
		functionName,
		hre.network.name,
	);

	return (await ethersSigner.sendTransaction(unsignedTx)).hash as Hash;
};
