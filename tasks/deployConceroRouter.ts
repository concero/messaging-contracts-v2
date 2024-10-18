import { task } from "hardhat/config";
import { compileContracts } from "../utils";
import { conceroNetworks, ProxyEnum } from "../constants";
import deployConceroRouter from "../deploy/ConceroRouter";
import deployProxyAdmin from "../deploy/ConceroProxyAdmin";
import deployTransparentProxy from "../deploy/TransparentProxy";

task("deploy-router", "Deploy the ConceroRouter contract")
    .addFlag("deployproxy", "Deploy the proxy")
    .addOptionalParam("chain", "The chain to deploy on")
    .setAction(async taskArgs => {
        compileContracts({ quiet: true });

        const hre = require("hardhat");
        const { name } = hre.network;

        let deployableChain;
        if (taskArgs.chain) {
            deployableChain = conceroNetworks[taskArgs.chain];
        } else {
            deployableChain = conceroNetworks[name];
        }

        await deployRouter({
            hre,
            deployableChain,
            deployProxy: taskArgs.deployproxy,
        });
    });

async function deployRouter(params) {
    const { hre, deployableChain, deployProxy } = params;
    const { name } = hre.network;

    if (deployProxy) {
        // Invoke deployProxy (implementation skipped)
        await deployProxyAdmin(hre, ProxyEnum.routerProxy);
        await deployTransparentProxy(hre, ProxyEnum.routerProxy);
    }

    // Deploy ConceroRouter
    await deployConceroRouter(hre, deployableChain);
}

export default {};
