import { task } from "hardhat/config";
import { compileContracts, getEnvVar } from "../../utils";
import { conceroNetworks, networkEnvKeys, ProxyEnum } from "../../constants";
import deployCLFRouter from "../../deploy/CLFRouter";
import deployProxyAdmin from "../../deploy/ConceroProxyAdmin";
import deployTransparentProxy from "../../deploy/TransparentProxy";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { setVariables } from "../deployConceroRouter/setVariables";
import { upgradeProxyImplementation } from "../upgradeProxyImplementation";
import { addCLFConsumer } from "../clf/addClfConsumer";
import { Address } from "viem";

export async function deployClfRouterTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
    compileContracts({ quiet: true });
    const conceroNetwork = conceroNetworks[hre.network.name];

    if (taskArgs.deployproxy) {
        await deployProxyAdmin(hre, ProxyEnum.clfRouterProxy);
        await deployTransparentProxy(hre, ProxyEnum.clfRouterProxy);
        const proxyAddress = getEnvVar(`CONCERO_ROUTER_PROXY_${networkEnvKeys[hre.network.name]}`) as Address;
        await addCLFConsumer(conceroNetwork, [proxyAddress]);
    }

    if (taskArgs.deployimplementation) {
        await deployCLFRouter(hre);
        await upgradeProxyImplementation(hre, ProxyEnum.clfRouterProxy, false);
    }

    if (taskArgs.setvars) {
        await setVariables(hre);
    }
}

task("deploy-clf-router", "Deploy the MasterChainCLF contract")
    .addFlag("deployproxy", "Deploy the proxy")
    .addFlag("deployimplementation", "Deploy the implementation")
    .addFlag("setvars", "Set the contract variables")
    .setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
        await deployClfRouterTask(taskArgs, hre);
    });

export default {};
