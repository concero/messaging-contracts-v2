import {consensusIdenticalAggregation, cre, Runtime} from "@chainlink/cre-sdk";
import {createPublicClient, custom, fallback, type PublicClient as ViemPublicClient, Transport} from "viem";

import {CRE, DomainError, ErrorCode, GlobalContext, Utility} from "../helpers";
import {ChainsManager} from "./chainsManager";


const chainSelectorToClient: Record<number, ViemPublicClient> = {}

const LOG_TAG = 'PublicClient'

export class PublicClient {
    static createHttpTransport (runtime: Runtime<GlobalContext>, url: string): Transport {
        return custom({
            async request({ method, params, }) {
                const body = [
                    {
                        jsonrpc: "2.0",
                        id: Date.now(),
                        method,
                        params
                    }
                ]
                const fetcher = CRE.buildFetcher(runtime, {
                    url,
                    method: "POST",
                    body,
                    headers: {
                        "Content-Type": "application/json",
                    }
                })

                const httpClient = new cre.capabilities.HTTPClient()
                const rawResponseBody = httpClient
                    .sendRequest(
                        runtime,
                        fetcher,
                        consensusIdenticalAggregation()
                    )(runtime.config)
                    .result()

                const responseBody: Record<number, Record<string, unknown>>[] = Utility.safeJSONParse(rawResponseBody);
                const result: any = (Object.values(responseBody || {}) as Record<string, unknown>[])?.map(i => i?.result)?.[0]
                console.log(`${LOG_TAG}|request Decoded: ${Utility.safeJSONStringify({rawResponseBody,responseBody,result})}`);

                return result
            }
        });
    }

    static create (runtime: Runtime<GlobalContext>, chainSelector: number): ViemPublicClient {
        if (chainSelectorToClient[chainSelector]) {
            return chainSelectorToClient[chainSelector];
        }

        const chain = ChainsManager.getOptionsBySelector(chainSelector)
        runtime.log(`${LOG_TAG}|create Got chain: ${JSON.stringify(chain)}`);
        if (!chain) {
            throw new DomainError(ErrorCode.NO_CHAIN_DATA, "Chain not found");
        }

        const client = createPublicClient({
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
            transport: fallback(chain.rpcUrls.map(i => PublicClient.createHttpTransport(runtime, i))),
        });
        chainSelectorToClient[chainSelector] = client;

        return client;
    }
}

