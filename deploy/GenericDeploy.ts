import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../constants";
import { EnvFileName } from "../types/deploymentVariables";
import { log, updateEnvAddress } from "../utils";
import { ContractPrefix } from "../utils/updateEnvVariable";

export interface ITxParams {
	gasLimit: bigint;
}

export interface IGenericDeployParams {
	hre: HardhatRuntimeEnvironment;
	contractName: string;
	contractPrefix: ContractPrefix;
	txParams?: Partial<ITxParams>;
}

export const genericDeploy = async (
	{ hre, contractName, contractPrefix, txParams }: IGenericDeployParams,
	...contractConstructorArgs: any[]
) => {
	const [deployer] = await hre.ethers.getSigners();
	const chain = conceroNetworks[hre.network.name];

	log(
		`Deploy ${contractName} from address: ${await deployer.getAddress()}`,
		"contract deploy",
		chain.name,
	);

	const contractFactory = await hre.ethers.getContractFactory(contractName, {
		...(txParams?.gasLimit && {
			estimateGas: () => new Promise(resolve => resolve(txParams.gasLimit!)),
		}),
	});
	const transactionData = (await contractFactory.getDeployTransaction(...contractConstructorArgs))
		.data;

	log(
		`${contractName} input data: ${transactionData} \n size: ${(transactionData.length - 2) / 2}`,
		"bytecode",
		chain.name,
	);

	const contract = await contractFactory.deploy(...contractConstructorArgs);
	await contract.deploymentTransaction()?.wait();
	const deploymentAddress = await contract.getAddress();

	await hre.tenderly.verify({
		name: contractName,
		address: deploymentAddress,
	});

	log(`Deployed at: ${deploymentAddress}`, `deploy ${contractName}`, chain.name);

	updateEnvAddress(
		contractPrefix,
		chain.name,
		deploymentAddress,
		`deployments.${chain.type}` as EnvFileName,
	);

	return contract.deploymentTransaction()?.hash;
};
