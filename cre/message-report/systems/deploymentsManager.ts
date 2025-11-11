import {consensusIdenticalAggregation, cre, Runtime} from "@chainlink/cre-sdk";
import {Address} from "viem";

import {CRE, DomainError, ErrorCode, GlobalContext} from "../helpers";
import {ChainsManager} from "./chainsManager";

export const chainSelectorToDeployment: Record<number, Address> = {};

export class DeploymentsManager {
    static fetchDeployments = (runtime: Runtime<GlobalContext>): string => {
        const fetcher = CRE.buildFetcher(runtime, {
            url: "https://raw.githubusercontent.com/concero/messaging-contracts-v2/refs/heads/master/.env.deployments.testnet",
            method: "GET",
            headers: {
                "Content-Type": "text/plain",
            }
        })

        const httpClient = new cre.capabilities.HTTPClient()
        return httpClient
            .sendRequest(
                runtime,
                fetcher,
                consensusIdenticalAggregation()
            )(runtime.config)
            .result()

    }
    static convertEnvNameToCamelCase(envName: string): string {
        return envName
            .split("_")
            .map((part, i) =>
                i === 0 ? part.toLowerCase() : part.charAt(0).toUpperCase() + part.slice(1).toLowerCase()
            )
            .join("");
    }
    static upsertDeploymentsFromEnv(envText: string): void {
        const lines = envText.split("\n");

        for (const line of lines) {
            if (!line || line.startsWith("#")) continue;
            const match = line.match(/^CONCERO_ROUTER_PROXY_(?!ADMIN_)([^=\n]+)=(0x[a-fA-F0-9]{40})$/);
            if (match) {
                const [, rawName, address] = match;
                const name = DeploymentsManager.convertEnvNameToCamelCase(rawName);
                const chainOptions = ChainsManager.findOptionsByName(name)
                console.log(JSON.stringify({line, match, rawName, address, name, chainOptions}))
                if (chainOptions) {
                    chainSelectorToDeployment[chainOptions.id] = address as Address;
                }
            }
        }
    }

    static enrichDeployments (runtime: Runtime<GlobalContext>) {
        const envs = DeploymentsManager.fetchDeployments(runtime)
        runtime.log(envs)
        DeploymentsManager.upsertDeploymentsFromEnv(envs)
    }

    static getDeploymentByChainSelector (chainSelector: number): Address {
        const found = chainSelectorToDeployment[chainSelector];

        if (!found) {
            throw new DomainError(ErrorCode.NO_CHAIN_DATA)
        }

        return found
    }

}