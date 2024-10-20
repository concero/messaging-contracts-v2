import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { conceroNetworks } from "../constants/conceroNetworks";
import log from "../utils/log";
import { getEnvAddress, updateEnvAddress } from "../utils";
import { IProxyType } from "../types/deploymentVariables";
import { writeContractConfig } from "../constants";

const deployTransparentProxy: (hre: HardhatRuntimeEnvironment, proxyType: IProxyType) => Promise<void> =
    async function (hre: HardhatRuntimeEnvironment, proxyType: IProxyType) {
        const { proxyDeployer } = await hre.getNamedAccounts();
        const { deploy } = hre.deployments;
        const { name, live } = hre.network;
        const networkType = conceroNetworks[name].type;

        const [initialImplementation, initialImplementationAlias] = getEnvAddress("pause", name);

        const [proxyAdmin, proxyAdminAlias] = getEnvAddress(`${proxyType}Admin`, name);

        const gasPrice = await hre.ethers.provider.getGasPrice();
        const maxFeePerGas = gasPrice.mul(2); // Set it to twice the base fee
        const maxPriorityFeePerGas = hre.ethers.utils.parseUnits("2", "gwei"); // Set a priority fee

        log("Deploying...", `deployTransparentProxy:${proxyType}`, name);
        const conceroProxyDeployment = (await deploy("TransparentUpgradeableProxy", {
            from: proxyDeployer,
            args: [initialImplementation, proxyAdmin, "0x"],
            log: true,
            autoMine: true,
            maxFeePerGas,
            maxPriorityFeePerGas,
            gasLimit: writeContractConfig.gas,
        })) as Deployment;

        log(
            `Deployed at: ${conceroProxyDeployment.address}. Initial impl: ${initialImplementationAlias}, Proxy admin: ${proxyAdminAlias}`,
            `deployTransparentProxy: ${proxyType}`,
            name,
        );
        updateEnvAddress(proxyType, name, conceroProxyDeployment.address, `deployments.${networkType}`);
    };

export default deployTransparentProxy;
deployTransparentProxy.tags = ["TransparentProxy"];
