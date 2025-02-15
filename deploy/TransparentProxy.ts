import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { conceroNetworks, writeContractConfig } from "../constants";
import log from "../utils/log";
import { getEnvAddress, updateEnvAddress } from "../utils";
import { IProxyType } from "../types/deploymentVariables";
import { getGasParameters } from "../utils/getGasParameters";

const deployTransparentProxy: (hre: HardhatRuntimeEnvironment, proxyType: IProxyType) => Promise<void> =
    async function (hre: HardhatRuntimeEnvironment, proxyType: IProxyType) {
        const { proxyDeployer } = await hre.getNamedAccounts();
        const { deploy } = hre.deployments;
        const { name, live } = hre.network;
        const chain = conceroNetworks[name];
        const { type } = chain;

        const [initialImplementation, initialImplementationAlias] = getEnvAddress("pause", name);
        const [proxyAdmin, proxyAdminAlias] = getEnvAddress(`${proxyType}Admin`, name);

        const { maxFeePerGas, maxPriorityFeePerGas } = await getGasParameters(chain);

        // log("Deploying...", `deployTransparentProxy:${proxyType}`, name);
        const conceroProxyDeployment = (await deploy("TransparentUpgradeableProxy", {
            from: proxyDeployer,
            args: [initialImplementation, proxyAdmin, "0x"],
            log: true,
            autoMine: true,
            skipIfAlreadyDeployed: false,
            maxFeePerGas,
            maxPriorityFeePerGas,
            gasLimit: writeContractConfig.gas,
        })) as Deployment;

        log(
            `Deployed at: ${conceroProxyDeployment.address}. Initial impl: ${initialImplementationAlias}, Proxy admin: ${proxyAdminAlias}`,
            `deployTransparentProxy: ${proxyType}`,
            name,
        );
        updateEnvAddress(proxyType, name, conceroProxyDeployment.address, `deployments.${type}`);
    };

export default deployTransparentProxy;
deployTransparentProxy.tags = ["TransparentProxy"];
