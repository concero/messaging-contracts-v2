import { task } from "hardhat/config";
import { compileContracts, getEnvAddress } from "../../utils";
import { conceroNetworks, ProxyEnum } from "../../constants";
import deployVerifier from "../../deploy/ConceroVerifier";
import deployProxyAdmin from "../../deploy/ConceroProxyAdmin";
import deployTransparentProxy from "../../deploy/TransparentProxy";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { setVerifierVariables } from "./setVerifierVariables";
import { upgradeProxyImplementation } from "../utils/upgradeProxyImplementation";
import { addCLFConsumer } from "../clf";

async function deployVerifierTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
    compileContracts({ quiet: true });
    const conceroNetwork = conceroNetworks[hre.network.name];

    if (taskArgs.deployproxy) {
        await deployProxyAdmin(hre, ProxyEnum.clfRouterProxy);
        await deployTransparentProxy(hre, ProxyEnum.clfRouterProxy);
        const [proxyAddress] = getEnvAddress(ProxyEnum.clfRouterProxy, hre.network.name);
        await addCLFConsumer(conceroNetwork, [proxyAddress]);
    }

    if (taskArgs.deployimplementation) {
        await deployVerifier(hre);
        await upgradeProxyImplementation(hre, ProxyEnum.clfRouterProxy, false);
    }

    if (taskArgs.setvars) {
        await setVerifierVariables(hre);
    }
}

task("deploy-clf-router", "Deploy the MasterChainCLF contract")
    .addFlag("deployproxy", "Deploy the proxy")
    .addFlag("deployimplementation", "Deploy the implementation")
    .addFlag("setvars", "Set the contract variables")
    .setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
        await deployVerifierTask(taskArgs, hre);
    });

export { deployVerifierTask };
