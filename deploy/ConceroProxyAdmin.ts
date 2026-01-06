import { HardhatRuntimeEnvironment } from "hardhat/types";

import { IProxyType } from "../types/deploymentVariables";
import { genericDeploy } from "./GenericDeploy";

export const deployProxyAdmin: (
	hre: HardhatRuntimeEnvironment,
	proxyType: IProxyType,
) => Promise<void> = async (hre: HardhatRuntimeEnvironment, proxyType: IProxyType) => {
	const [deployer] = await hre.ethers.getSigners();

	await genericDeploy(
		{
			hre,
			contractName: "ProxyAdmin",
			contractPrefix: `${proxyType}Admin`,
		},
		deployer.address,
	);
};
