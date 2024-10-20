import { err, formatGas, getEnvAddress, getFallbackClients, log } from "../utils";
import { conceroNetworks, ProxyEnum, writeContractConfig } from "../constants";
import { task } from "hardhat/config";
import { EnvPrefixes, IProxyType } from "../types/deploymentVariables";
import { getViemAccount } from "../utils/getViemClients";
import { getViemReceiptConfig } from "../constants/deploymentVariables";

export async function upgradeProxyImplementation(hre, proxyType: IProxyType, shouldPause: boolean) {
    const { name: chainName } = hre.network;
    const { viemChain, type } = conceroNetworks[chainName];

    let implementationKey: keyof EnvPrefixes;

    if (shouldPause) {
        implementationKey = "pause";
    } else if (proxyType === ProxyEnum.routerProxy) {
        implementationKey = "router";
    } else if (proxyType === ProxyEnum.clfRouterProxy) {
        implementationKey = "clfRouter";
    } else {
        err(`Proxy type ${proxyType} not found`, "upgradeProxyImplementation", chainName);
        return;
    }

    const { abi: proxyAdminAbi } = await import(
        "../artifacts/contracts/Proxy/ConceroProxyAdmin.sol/ConceroProxyAdmin.json"
    );

    const viemAccount = getViemAccount(type, "proxyDeployer");
    const { walletClient, publicClient } = getFallbackClients(conceroNetworks[chainName], viemAccount);

    const [conceroProxy, conceroProxyAlias] = getEnvAddress(proxyType, chainName);
    const [proxyAdmin, proxyAdminAlias] = getEnvAddress(`${proxyType}Admin`, chainName);
    const [newImplementation, newImplementationAlias] = getEnvAddress(implementationKey, chainName);
    const [pauseDummy, pauseAlias] = getEnvAddress("pause", chainName);

    const implementation = shouldPause ? pauseDummy : newImplementation;
    const implementationAlias = shouldPause ? pauseAlias : newImplementationAlias;

    const txHash = await walletClient.writeContract({
        ...writeContractConfig,
        address: proxyAdmin,
        abi: proxyAdminAbi,
        functionName: "upgradeAndCall",
        account: viemAccount,
        args: [conceroProxy, implementation, "0x"],
        chain: viemChain,
    });

    const { cumulativeGasUsed } = await publicClient.waitForTransactionReceipt({
        ...getViemReceiptConfig(conceroNetworks[chainName]),
        hash: txHash,
    });

    log(
        `Upgraded via ${proxyAdminAlias}: ${conceroProxyAlias}.implementation -> ${implementationAlias}. Gas : ${formatGas(cumulativeGasUsed)}, hash: ${txHash}`,
        `setProxyImplementation : ${proxyType}`,
        chainName,
    );
}

export default {};

task("upgrade-proxy-implementation", "Upgrades the proxy implementation")
    .addFlag("pause", "Pause the proxy before upgrading", false)
    .addParam("proxytype", "The type of the proxy to upgrade", undefined)
    .setAction(async taskArgs => {
        await upgradeProxyImplementation(hre, taskArgs.proxytype, taskArgs.pause);
    });
