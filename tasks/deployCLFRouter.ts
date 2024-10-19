import { task } from "hardhat/config";
import { compileContracts } from "../utils";
import { ProxyEnum } from "../constants";
import deployCLFRouter from "../deploy/CLFRouter";
import deployProxyAdmin from "../deploy/ConceroProxyAdmin";
import deployTransparentProxy from "../deploy/TransparentProxy";
import { HardhatRuntimeEnvironment } from "hardhat/types";

task("deploy-clf-router", "Deploy the MasterChainCLF contract")
    .addFlag("deployproxy", "Deploy the proxy")
    .setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
        compileContracts({ quiet: true });
        // const { live, name } = hre.network;

        if (taskArgs.deployproxy) {
            await deployProxyAdmin(hre, ProxyEnum.routerProxy);
            await deployTransparentProxy(hre, ProxyEnum.routerProxy);
        }
        await deployCLFRouter(hre);
    });

export default {};
