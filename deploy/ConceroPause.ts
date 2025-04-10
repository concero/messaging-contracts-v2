import { HardhatRuntimeEnvironment } from "hardhat/types";

import { networkEnvKeys } from "../constants";
import { conceroNetworks } from "../constants/conceroNetworks";
import { getFallbackClients } from "../utils";
import log from "../utils/log";
import updateEnvVariable from "../utils/updateEnvVariable";

const deployPauseDummy: (hre: HardhatRuntimeEnvironment) => Promise<void> = async function (
	hre: HardhatRuntimeEnvironment,
) {
	const { deployer } = await hre.getNamedAccounts();
	const { deploy } = hre.deployments;
	const { name, live } = hre.network;
	const networkType = conceroNetworks[name].type;
	const conceroNetwork = conceroNetworks[name];

	console.log("Deploying...", "deployPauseDummy", name);

	const { walletClient, publicClient } = getFallbackClients(conceroNetwork);
	const bytecode =
		"0x6080604052348015600f57600080fd5b5060b080601d6000396000f3fe608060405236603e5760405162461bcd60e51b81526020600482015260066024820152651c185d5cd95960d21b60448201526064015b60405180910390fd5b348015604957600080fd5b5060405162461bcd60e51b81526020600482015260066024820152651c185d5cd95960d21b6044820152606401603556fea26469706673582212202ff9e4b2f95a91637fc46df003edb012fc49fdf8ed9c5d5dae2851be7bbcc57064736f6c634300081c0033";

	// const deployPauseDummy = (await deploy("PauseDummy", {
	// 	from: deployer,
	// 	args: [],
	// })) as Deployment;

	const deployHash = await walletClient.deployContract({
		bytecode,
	});

	const { status } = await publicClient.waitForTransactionReceipt({ hash: deployHash });

	console.log(deployHash);
	console.log(status);

	if (live) {
		log(`Deployed at: ${deployPauseDummy.address}`, "deployPauseDummy", name);
		updateEnvVariable(
			`CONCERO_PAUSE_${networkEnvKeys[name]}`,
			deployPauseDummy.address,
			`deployments.${networkType}`,
		);
	}
};

export default deployPauseDummy;
deployPauseDummy.tags = ["ConceroPause"];
