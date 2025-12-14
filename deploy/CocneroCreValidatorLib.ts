import { HardhatRuntimeEnvironment } from "hardhat/types";

import { genericDeploy } from "./GenericDeploy";

const deployConceroCreValidatorLib = async function (hre: HardhatRuntimeEnvironment) {
	await genericDeploy({
		hre,
		contractName: "CreValidatorLib",
		contractPrefix: "creValidatorLib",
	});
};

export { deployConceroCreValidatorLib };
export default deployConceroCreValidatorLib;
