import * as envEnc from "@chainlink/env-enc";
import * as dotenv from "dotenv";

const BASE_ENV_FILES = [".env", ".env.clf", ".env.clccip", ".env.tokens", ".env.wallets"];

const STAGE_ENV = [".env.deployments.stage"];

const ENV_FILES = [
	".env.deployments.mainnet",
	".env.deployments.testnet",
	".env.deployments.localhost",
];

/**
 * Returns the list of deployment files depending on DEPLOY_TO_STAGE
 */
function getDeploymentEnvFiles(): string[] {
	const deployToStage = process.env.DEPLOY_TO_STAGE?.toLowerCase();

	if (deployToStage === "true") {
		return STAGE_ENV;
	}

	return ENV_FILES;
}

/**
 * Configures the dotenv with paths relative to a base directory.
 * @param {string} [basePath='../../../'] - The base path where .env files are located. Defaults to '../../'.
 */
function configureDotEnv(basePath = "./") {
	const normalizedBasePath = basePath.endsWith("/") ? basePath : `${basePath}/`;

	BASE_ENV_FILES.forEach(file => {
		dotenv.config({ path: `${normalizedBasePath}${file}` });
	});

	const deploymentFiles = getDeploymentEnvFiles();
	deploymentFiles.forEach(file => {
		dotenv.config({ path: `${normalizedBasePath}${file}` });
	});

	envEnc.config({ path: process.env.PATH_TO_ENC_FILE });
}

configureDotEnv();

export { configureDotEnv };
