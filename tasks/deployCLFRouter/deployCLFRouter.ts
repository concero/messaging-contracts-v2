import { task } from "hardhat/config";
import { compileContracts } from "../../utils";
import { conceroNetworks, ProxyEnum } from "../../constants";
import deployCLFRouter from "../../deploy/CLFRouter";
import deployProxyAdmin from "../../deploy/ConceroProxyAdmin";
import deployTransparentProxy from "../../deploy/TransparentProxy";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { setVariables } from "../deployConceroRouter/setVariables";
import { upgradeProxyImplementation } from "../upgradeProxyImplementation";
import { uploadClfSecrets } from "../clf/uploadClfSecrets";

export async function deployClfRouterTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
    compileContracts({ quiet: true });
    // const { live, name } = hre.network;
    const conceroNetwork = conceroNetworks[hre.network.name];

    if (taskArgs.deployproxy) {
        await deployProxyAdmin(hre, ProxyEnum.routerProxy);
        await deployTransparentProxy(hre, ProxyEnum.routerProxy);
    }
    if (taskArgs.uploadsecrets) {
        const slotId = taskArgs.slotid ?? 0;
        await uploadClfSecrets([conceroNetwork], slotId);
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
