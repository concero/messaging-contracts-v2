import { getNetworkEnvKey } from "@concero/contract-utils";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../constants";
import { log, updateEnvVariable } from "../utils";

const deployRouter = async function (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: Partial<undefined>,
) {
	const [deployer] = await hre.ethers.getSigners();
	const chain = conceroNetworks[hre.network.name];
	const args = {
		chainSelector: chain.chainSelector,
	};
	const contractName = "ConceroRouter";

	log(
		`Deploy ${contractName} from address: ${await deployer.getAddress()}`,
		"contract deploy",
		chain.name,
	);

	const contractFactory = await hre.ethers.getContractFactory(contractName);
	const transactionData = (await contractFactory.getDeployTransaction(chain.chainId)).data;

	log(
		`${contractName} input data: ${transactionData} \n size: ${(transactionData.length - 2) / 2}`,
		"bytecode",
		chain.name,
	);

	const contract = await contractFactory.deploy(args.chainSelector);
	const deploymentAddress = await contract.getAddress();

	await hre.tenderly.verify({
		name: contractName,
		address: deploymentAddress,
	});

	log(`Deployed at: ${deploymentAddress}`, "deployRouter", name);
	updateEnvVariable(
		`CONCERO_ROUTER_${getNetworkEnvKey(name)}`,
		deploymentAddress,
		`deployments.${chain.networkType}`,
	);
};

export { deployRouter };
