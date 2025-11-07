import {consensusIdenticalAggregation, cre, Report, Runtime} from "@chainlink/cre-sdk";
import {CRE, GlobalContext} from "../helpers";

export class DeploymentsManager {
    enrichDeployments = (runtime: Runtime<GlobalContext>, report: Report): void => {
        const fetcher = CRE.buildFetcher(runtime, {
            url: "https://raw.githubusercontent.com/concero/messaging-contracts-v2/refs/heads/master/.env.deployments.testnet",
            method: "POST",
            headers: {
                "Content-Type": "text/plain",
            }
        })

        const httpClient = new cre.capabilities.HTTPClient()
        const rawEnvironments = httpClient
            .sendRequest(
                runtime,
                fetcher,
                consensusIdenticalAggregation()
            )(runtime.config)
            .result()
        console.log(rawEnvironments)
    }
}