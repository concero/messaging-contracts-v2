import { execSync } from "child_process";
import fs from "fs";

import { task } from "hardhat/config";

import { networkEnvKeys } from "../../constants";
import { getEnvVar } from "../../utils";
import { prepareCLFDist } from "./prepareCLFDist";

export function buildClfJs() {
	const hre = require("hardhat");

	try {
		const networkName = hre.network.name;
		const conceroVerifier = getEnvVar(`CONCERO_VERIFIER_${networkEnvKeys[networkName]}`);
		const conceroRouter = getEnvVar(`CONCERO_ROUTER_${networkEnvKeys[networkName]}`);

		// Base esbuild command with common options
		const cmdBase =
			`esbuild --bundle --legal-comments=none --format=esm --global-name=conceromain --target=esnext ` +
			`--define:CONCERO_VERIFIER='"${conceroVerifier}"' ` +
			`--define:CONCERO_ROUTER_OPTIMISM='"${conceroRouter}"' ` +
			`--define:CONCERO_ROUTER_ETHEREUM='"${conceroRouter}"' `;

		// Get all directories in clf/src
		const dirs = execSync("ls -d */", { cwd: "clf/src" }).toString();
		const dirsArray = dirs
			.split("\n")
			.filter(dir => dir !== "")
			.map(dir => dir.replace(/\/$/, "")); // Remove trailing slash

		// For each directory, build standard and minified versions if they have an index.ts file
		dirsArray.forEach(dir => {
			const dirLs = execSync("ls", { cwd: `clf/src/${dir}` });

			if (!dirLs.toString().includes("index.ts")) return;

			// Build standard version
			execSync(`${cmdBase} --outfile=clf/dist/${dir}.js ./clf/src/${dir}/index.ts`, {
				stdio: "inherit",
			});

			// Build minified version
			execSync(
				`${cmdBase} --minify --outfile=clf/dist/${dir}.min.js ./clf/src/${dir}/index.ts`,
				{
					stdio: "inherit",
				},
			);

			// Process the minified file with prepareCLFDist
			const minFilePath = `clf/dist/${dir}.min.js`;
			const fileContent = fs.readFileSync(minFilePath, "utf8");
			const processedContent = prepareCLFDist(fileContent);
			fs.writeFileSync(minFilePath, processedContent);
			console.log(`Processed ${minFilePath}`);
		});
	} catch (e) {
		console.error(e?.toString());
	}
}

task("clf-build-js", "Build CLF JavaScript files using esbuild").setAction(async (_, __) => {
	buildClfJs();
});
