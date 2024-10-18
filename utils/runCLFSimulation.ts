import fs from "fs";
import { CLFSimulationConfig, secrets } from "../constants";
import { simulateScript } from "@chainlink/functions-toolkit";
import type { SimulationResult } from "@chainlink/functions-toolkit/dist/types";
import { execSync } from "child_process";

export enum CLFType {
    requestReport = "requestReport",
}

const getPathToCLFFileByType = (clfType: CLFType): string | undefined => {
    switch (clfType) {
        case CLFType.requestReport:
            return "./clf/dist/requestReport.min.js";
    }
};

function printSimulationResult(results: SimulationResult[]) {
    for (const result of results) {
        const { errorString, capturedTerminalOutput, responseBytesHexstring } = result;

        if (errorString) {
            console.log("CAPTURED ERROR:");
            console.log(errorString);
        }

        if (capturedTerminalOutput) {
            console.log("CAPTURED TERMINAL OUTPUT:");
            console.log(capturedTerminalOutput);
        }

        if (responseBytesHexstring) {
            console.log("RESPONSE BYTES HEXSTRING:");
            console.log(responseBytesHexstring);
        }
    }
}

export interface CLFSimulationOptions {
    print?: boolean;
    rebuild?: boolean;
}

export async function runCLFSimulation(clfType: CLFType, args: string[], options: CLFSimulationOptions) {
    const { print, rebuild } = options;

    if (rebuild) {
        execSync(`yarn hardhat clf-script-build --all`, { stdio: "inherit" });
    }

    const pathToFile = getPathToCLFFileByType(clfType);

    if (!pathToFile) {
        throw new Error("Invalid CLF type");
    }

    if (!fs.existsSync(pathToFile)) {
        throw new Error(`File not found: ${pathToFile}`);
    }

    let promises = [];
    for (let i = 0; i < 1; i++) {
        promises.push(
            simulateScript({
                source:
                    'const ethers = await import("npm:ethers@6.10.0"); return' + fs.readFileSync(pathToFile, "utf8"),
                bytesArgs: args,
                secrets,
                ...CLFSimulationConfig,
            }),
        );
    }

    const results = await Promise.all(promises);

    if (print) {
        printSimulationResult(results);
    }

    return results;
}
