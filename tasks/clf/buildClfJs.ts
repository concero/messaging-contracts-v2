import { execSync } from "child_process";
import fs from "fs";

import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { getNetworkEnvKey } from "@concero/contract-utils";
import { testnetNetworks } from "@concero/v2-networks";

import { getEnvVar } from "../../utils";
import { prepareCLFDist } from "./prepareCLFDist";

/**
 * Process a file with prepareCLFDist and save the result back to the same file
 */
function processFile(filePath: string, isMinified: boolean = false): void {
	try {
		const fileContent = fs.readFileSync(filePath, "utf8");
		const processedContent = prepareCLFDist(fileContent, isMinified);
		fs.writeFileSync(filePath, processedContent);
		console.log(`Processed ${filePath}`);
	} catch (error) {
		console.error(`Error processing ${filePath}:`, error);
	}
}

export function buildClfJs(networkName: string) {
	try {
		const conceroVerifier = getEnvVar(
			`CONCERO_VERIFIER_PROXY_${getNetworkEnvKey(networkName)}`,
		);

		// Use npx to ensure esbuild is available from node_modules
		const cmdBase =
			`npx esbuild --bundle --legal-comments=none --format=esm --global-name=conceromain --target=esnext ` +
			Object.values(testnetNetworks).reduce((acc, e) => {
				return (
					acc +
					`--define:CONCERO_ROUTER_${getNetworkEnvKey(e.name)}='"${getEnvVar(`CONCERO_ROUTER_PROXY_${getNetworkEnvKey(e.name)}`)}"' `
				);
			}, "") +
			`--define:CONCERO_VERIFIER='"${conceroVerifier}"'`;

		// Get all directories in clf/src
		const dirs = execSync("ls -d */", { cwd: "clf/src" }).toString();
		const dirsArray = dirs
			.split("\n")
			.filter(dir => dir !== "")
			.map(dir => dir.replace(/\/$/, "")); // Remove trailing slash

		dirsArray.forEach(dir => {
			const dirLs = execSync("ls", { cwd: `clf/src/${dir}` });

			if (!dirLs.toString().includes("index.ts")) return;

			// Build standard version
			execSync(`${cmdBase} --outfile=clf/dist/${dir}.js ./clf/src/${dir}/index.ts`, {
				stdio: "inherit",
				shell: true,
			});

			// Process the standard (unminified) file
			processFile(`clf/dist/${dir}.js`, false);

			// Build minified version
			execSync(
				`${cmdBase} --minify --outfile=clf/dist/${dir}.min.js ./clf/src/${dir}/index.ts`,
				{
					stdio: "inherit",
					shell: true,
				},
			);

			// Process the minified file
			processFile(`clf/dist/${dir}.min.js`, true);
		});
	} catch (e) {
		console.error(e?.toString());
	}
}

task("clf-build-js", "Build CLF JavaScript files using esbuild").setAction(async (_, __) => {
	const hre: HardhatRuntimeEnvironment = require("hardhat");
	buildClfJs(hre.network.name);
});
