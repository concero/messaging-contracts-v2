import fs from "fs";
import path from "path";

import * as dotenv from "dotenv";

const ENV_FILES = [".env", ".env.deployments.mainnet", ".env.deployments.testnet", ".env.test"];

/**
 * Configures the dotenv with paths relative to a base directory.
 * @param {string} [basePath='../../../'] - The base path where .env files are located. Defaults to '../../'.
 */
function configureDotEnv(basePath = "./") {
	const absoluteBasePath = path.resolve(process.cwd(), basePath);

	ENV_FILES.forEach(file => {
		const envPath = path.join(absoluteBasePath, file);
		if (fs.existsSync(envPath)) {
			dotenv.config({ path: envPath, override: true });
		}
	});
}

function reloadDotEnv(basePath = "../../") {
	const normalizedBasePath = basePath.endsWith("/") ? basePath : `${basePath}/`;

	ENV_FILES.forEach(file => {
		const fullPath = `${normalizedBasePath}${file}`;
		const currentEnv = dotenv.parse(fs.readFileSync(fullPath));

		Object.keys(currentEnv).forEach(key => {
			delete process.env[key];
		});

		dotenv.config({ path: fullPath });
	});
}

export { configureDotEnv, reloadDotEnv };
