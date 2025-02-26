import { execSync } from "child_process";
import { task } from "hardhat/config";

export function buildClfJs() {
    try {
        const dirs = execSync("ls -d */", { cwd: "clf/src" }).toString();
        const dirsArray = dirs
            .split("\n")
            .filter(dir => dir !== "")
            // Remove trailing slash from each directory name
            .map(dir => dir.replace(/\/$/, ""));

        dirsArray.forEach(dir => {
            const dirLs = execSync("ls", { cwd: `clf/src/${dir}` });

            if (!dirLs.toString().includes("index.ts")) return;

            execSync(`bun build index.ts --outfile=../../dist/${dir}.js`, { cwd: `clf/src/${dir}` });
            execSync(`bun build index.ts --minify --outfile=../../dist/${dir}.min.js`, { cwd: `clf/src/${dir}` });
        });
    } catch (e) {
        console.error(e?.toString());
    }
}

task("clf-build-js", "").setAction(async (_, __) => {
    buildClfJs();
});

export default {};
