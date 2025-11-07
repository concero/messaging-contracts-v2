import { consensusIdenticalAggregation, cre, type HTTPSendRequester, ok, Runtime } from "@chainlink/cre-sdk";
import { createPublicClient, custom, fallback } from "viem";

import { DomainError, ErrorCode } from "../error";
import { getChainOptionsByChainSelector } from "./chainOptions";
import { GlobalContext } from "../types";
import { Utility } from "../utility";


const LOG_TAG = 'getPublicClient'

const createCustomHttpTransport = (runtime: Runtime<GlobalContext>, url: string) => custom({
    async request({ method, params, }) {
        const fetcher = (sendRequester: HTTPSendRequester, _: GlobalContext) => {
            const requestBodyBytes = new TextEncoder().encode(JSON.stringify([{ method, params }]))
            const requestBody = Buffer.from(requestBodyBytes).toString("base64")

            const req = {
                url,
                method: 'POST',
                body: requestBody,
                headers: {
                    "Content-Type": "application/json",
                },
            }

            runtime.log(`${LOG_TAG}|fetcher Send: ${JSON.stringify(req)}`);

            const response = sendRequester.sendRequest(req).result()
            runtime.log(`${LOG_TAG}|fetcher Respond: ${Utility.safeJSONStringify(response)}`);

            if (!ok(response)) {
                throw new Error(`${LOG_TAG}|fetcher HTTP request failed with status: ${response.statusCode}`)
            }

            const rawResponseBody = new TextDecoder().decode(response.body);
            const responseBody: Record<number, Record<string, unknown>>[] = Utility.safeJSONParse(rawResponseBody);
            const result: any = (Object.values(responseBody || {}) as Record<string, unknown>[]).map(i => i?.result)?.[0]
            console.log(`${LOG_TAG}|fetcher Decoded: ${Utility.safeJSONStringify(result)}`);

            return result
        }

        const httpClient = new cre.capabilities.HTTPClient()

        return httpClient
            .sendRequest(
                runtime,
                fetcher,
                consensusIdenticalAggregation<any>()
            )(runtime.config)
            .result()
    }
});

export function getPublicClient(runtime: Runtime<GlobalContext>, chainSelector: number) {
    const chain = getChainOptionsByChainSelector(chainSelector)
    runtime.log(`Got chain: ${JSON.stringify(chain)}`);
    if (!chain) {
        throw new DomainError(ErrorCode.INVALID_CHAIN_DATA, "Chain not found");
    }

    return createPublicClient({
        chain: {
            id: chain.id,
            name: chain.name,
            nativeCurrency: chain.nativeCurrency as any,
            rpcUrls: {
                default: {
                    http: chain.rpcUrls
                }
            }
        },
        transport: fallback(chain.rpcUrls.map(i => createCustomHttpTransport(runtime, i))),
	});
}
