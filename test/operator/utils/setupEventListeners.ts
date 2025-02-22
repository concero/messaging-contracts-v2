import { Log, getAbiItem } from "viem";
import { setupEventListener } from "@concero/v2-operators/src/relayer/common/eventListener/setupEventListener";
import { decodeLogs } from "@concero/v2-operators/src/relayer/common/eventListener/decodeLogs";
import { getCLFReport, getOperatorRegistrationCLFResponse } from "../getOperatorRegistrationCLFResponse";
import { globalConfig, networkEnvKeys } from "@concero/v2-operators/src/constants";
import { config } from "@concero/v2-operators/src/relayer/a/constants";
import { getEnvVar } from "../../../utils";

const OPERATOR_REGISTRY_EVENT = "OperatorRegistrationRequested";

const logsAbi = [
    getAbiItem({
        abi: globalConfig.ABI.CONCERO_VERIFIER,
        name: OPERATOR_REGISTRY_EVENT,
    }),
];

// console.log(JSON.stringify(logsAbi, null, 2));
async function onOperatorRegistryLogs(logs: Log[]) {
    const decodedLogs = decodeLogs(logs, globalConfig.ABI.CONCERO_VERIFIER);

    for (const log of decodedLogs) {
        if (log.eventName === OPERATOR_REGISTRY_EVENT) {
            const operatorRegistrationCLFResponseBytes = await getOperatorRegistrationCLFResponse();
            const clfReport = await getCLFReport(operatorRegistrationCLFResponseBytes);
        }
    }
}

async function setupOperatorRegistrationEventListener() {
    const network = config.networks.conceroVerifier;
    const conceroVerifier = getEnvVar(`CONCERO_VERIFIER_${networkEnvKeys[network.name]}`);

    await setupEventListener(network, conceroVerifier, onOperatorRegistryLogs, config.POLLING_INTERVAL_MS);
}

export { setupOperatorRegistrationEventListener };
