import { HardhatRuntimeEnvironment } from "hardhat/types";

import { EnvFileName } from "../types/deploymentVariables";
import { genericDeploy, getEnvFileName, updateEnvAddress } from "../utils";

export const deployConceroCreValidatorLib = async (hre: HardhatRuntimeEnvironment) => {
	const deployment = await genericDeploy({
		hre,
		contractName: "CreValidatorLib",
	});

	updateEnvAddress(
		"creValidatorLib",
		deployment.address,
		getEnvFileName(`deployments.${deployment.chainType}` as EnvFileName),
		deployment.chainName,
	);
};
