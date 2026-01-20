import { HardhatRuntimeEnvironment } from "hardhat/types";

import { EnvFileName } from "../types/deploymentVariables";
import { genericDeploy } from "../utils";
import { getEnvFileName, updateEnvAddress } from "../utils";

const deployConceroCreValidatorLib = async function (hre: HardhatRuntimeEnvironment) {
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

export { deployConceroCreValidatorLib };
export default deployConceroCreValidatorLib;
