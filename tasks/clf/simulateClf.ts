import { task, types } from "hardhat/config";
import fs from "fs";
import path from "path";
import { simulateScript } from "@chainlink/functions-toolkit";
import { log } from "../../utils";
import secrets from "../../constants/CLFSecrets";
import CLFSimulationConfig from "../../constants/CLFSimulationConfig";
import getSimulationArgs from "./simulationArgs";

/**
 * Simulates the execution of a script with the given arguments.
 * @param scriptPath - The path to the script file to simulate.
 * @param scriptName - The name of the script to simulate.
 * @param args - The array of arguments to pass to the simulation.
 */
export async function simulateCLFScript(
    scriptPath: string,
    scriptName: string,
    args: string[],
    secretsOverride?: any,
): Promise<string | undefined> {
    if (!fs.existsSync(scriptPath)) {
        console.error(`File not found: ${scriptPath}`);
        return;
    }

    log(`Simulating ${scriptPath}`, "simulateCLFScript");
    try {
        const result = await simulateScript({
            source: fs.readFileSync(scriptPath, "utf8"),
            bytesArgs: args,
            secrets: {
                ...secrets,
                ...{
                    CONCERO_CLF_DEVELOPMENT: "true",
                    LOCALHOST_RPC_URL: process.env.LOCALHOST_RPC_URL,
                    CONCERO_VERIFIER_LOCALHOST: secretsOverride?.CONCERO_VERIFIER_LOCALHOST,
                },
            },
            ...CLFSimulationConfig,
        });

        const { errorString, capturedTerminalOutput, responseBytesHexstring } = result;

        if (errorString) {
            log(errorString, "simulateCLFScript – Error:");
        }

        if (capturedTerminalOutput) {
            log(capturedTerminalOutput, "simulateCLFScript – Terminal output:");
        }

        if (responseBytesHexstring) {
            log(responseBytesHexstring, "simulateCLFScript – Response Bytes:");
            // const decodedResponse = decodeCLFResponse(scriptName, responseBytesHexstring);
            // if (decodedResponse) {
            //     log(decodedResponse, "simulateCLFScript – Decoded Response:");
            // }
            return responseBytesHexstring;
        }
    } catch (error) {
        console.error("Simulation failed:", error);
    }
}

task("clf-script-simulate", "Executes the JavaScript source code locally")
    .addParam("name", "Name of the function to simulate", "operatorRegistration", types.string)
    .addOptionalParam("concurrency", "Number of concurrent requests", 1, types.int)
    .setAction(async taskArgs => {
        const scriptName = taskArgs.name;
        const basePath = path.join(__dirname, "../../", "./clf/dist");
        let scriptPath: string;

        switch (scriptName) {
            case "operatorRegistration":
                scriptPath = path.join(basePath, "./operatorRegistration.min.js");
                break;
            case "messageReport":
                scriptPath = path.join(basePath, "./messageReport.min.js");
                break;
            default:
                console.error(`Unknown function: ${scriptName}`);
                return;
        }

        if (!getSimulationArgs[scriptName]) {
            console.error(`No simulation arguments found for: ${scriptName}`);
            return;
        }

        const bytesArgs = await getSimulationArgs[scriptName]();
        const concurrency = taskArgs.concurrency;
        const promises = Array.from({ length: concurrency }, () =>
            simulateCLFScript(scriptPath, scriptName, bytesArgs),
        );
        await Promise.all(promises);
    });
