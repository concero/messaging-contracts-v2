import type { WaitForTransactionReceiptParameters } from "viem/actions/public/waitForTransactionReceipt";
import { WriteContractParameters } from "viem";
import { EnvPrefixes } from "../types/deploymentVariables";

export const viemReceiptConfig: WaitForTransactionReceiptParameters = {
    timeout: 0,
    confirmations: 2,
};
export const writeContractConfig: WriteContractParameters = {
    gas: 3000000n, // 3M
};
export enum ProxyEnum {
    routerProxy = "routerProxy",
    clfRouterProxy = "clfRouterProxy",
}

export const envPrefixes: EnvPrefixes = {
    router: "CONCERO_ROUTER",
    clfRouter: "CONCERO_CLF_ROUTER",
    routerProxy: "CONCERO_ROUTER_PROXY",
    routerProxyAdmin: "CONCERO_ROUTER_PROXY_ADMIN",
    clfRouterProxy: "CONCERO_CLF_ROUTER_PROXY",
    clfRouterProxyAdmin: "CONCERO_CLF_ROUTER_PROXY_ADMIN",
    lpToken: "LPTOKEN",
    create3Factory: "CREATE3_FACTORY",
    pause: "CONCERO_PAUSE",
};
