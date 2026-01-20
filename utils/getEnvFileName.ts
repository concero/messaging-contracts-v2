import { EnvFileName } from "../types/deploymentVariables";

export function getEnvFileName(envFileName: EnvFileName): EnvFileName {
	const deployEnv = process.env.DEPLOY_TO_STAGE?.toLowerCase();
	if (deployEnv === "true") {
		return "deployments.stage";
	}
	return envFileName;
}
