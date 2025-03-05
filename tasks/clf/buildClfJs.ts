import { execSync } from "child_process";
import { task } from "hardhat/config";

import { networkEnvKeys } from "../../constants";
import { getEnvVar } from "../../utils";

export function buildClfJs() {
	const hre = require("hardhat");

	try {
		const networkName = hre.network.name;
		const conceroVerifier = getEnvVar(`CONCERO_VERIFIER_${networkEnvKeys[networkName]}`);
		const conceroRouter = getEnvVar(`CONCERO_ROUTER_${networkEnvKeys[networkName]}`);
		const cmdBase = `bun build index.ts --define CONCERO_VERIFIER='"${conceroVerifier}"' --define CONCERO_ROUTER='"${conceroRouter}"' `;
		const dirs = execSync("ls -d */", { cwd: "clf/src" }).toString();
		const dirsArray = dirs
			.split("\n")
			.filter(dir => dir !== "")
			// Remove trailing slash from each directory name
			.map(dir => dir.replace(/\/$/, ""));

		// execSync("bun build eval.js --minify --outfile=../dist/eval.js", {
		// 	cwd: `clf/src/`,
		// });

		dirsArray.forEach(dir => {
			const dirLs = execSync("ls", { cwd: `clf/src/${dir}` });

			if (!dirLs.toString().includes("index.ts")) return;

			execSync(cmdBase + `--outfile=../../dist/${dir}.js`, {
				cwd: `clf/src/${dir}`,
			});
			execSync(cmdBase + `--minify --outfile=../../dist/${dir}.min.js`, {
				cwd: `clf/src/${dir}`,
			});
		});
	} catch (e) {
		console.error(e?.toString());
	}
}

task("clf-build-js", "").setAction(async (_, __) => {
	buildClfJs();
});
