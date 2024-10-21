import { task } from "hardhat/config";
import { compileContracts, getEnvAddress } from "../../utils";
import { conceroNetworks, ProxyEnum } from "../../constants";
import deployCLFRouter from "../../deploy/CLFRouter";
import deployProxyAdmin from "../../deploy/ConceroProxyAdmin";
import deployTransparentProxy from "../../deploy/TransparentProxy";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { setVariables } from "./setVariables";
import { upgradeProxyImplementation } from "../upgradeProxyImplementation";
import { addCLFConsumer } from "../clf/addClfConsumer";

export async function deployClfRouterTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
    compileContracts({ quiet: true });
    const conceroNetwork = conceroNetworks[hre.network.name];

    if (taskArgs.deployproxy) {
        await deployProxyAdmin(hre, ProxyEnum.clfRouterProxy);
        await deployTransparentProxy(hre, ProxyEnum.clfRouterProxy);
        const [proxyAddress] = getEnvAddress(ProxyEnum.clfRouterProxy, hre.network.name);
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
