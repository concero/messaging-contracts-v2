import { ProxyEnum } from "../constants";

export type IProxyType = keyof typeof ProxyEnum;

type ProxyEnvPrefixes = {
    [key in ProxyEnum]: string;
};
export type EnvPrefixes = {
    router: string;
    routerProxy: string;
    clfRouter: string;
    clfRouterProxy: string;
    routerProxyAdmin: string;
    clfRouterProxyAdmin: string;
    lpToken: string;
    create3Factory: string;
    pause: string;
};
/**
 * Update an environment variable in the .env file
 * @param key The key of the environment variable to update
 * @param newValue The new value of the environment variable
 * @param envFileName The name of the .env file to update
 * usage: // updateEnvVariable("CLF_DON_SECRETS_VERSION_SEPOLIA", "1712841283", "../../../.env.clf");
 */
export type EnvFileName = "cla" | "clf" | "ccip" | "deployments.mainnet" | "deployments.testnet" | "apikeys" | "tokens";
