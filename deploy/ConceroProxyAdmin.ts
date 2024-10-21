import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { conceroNetworks, writeContractConfig } from "../constants";
import { getWallet, updateEnvAddress } from "../utils";
import log from "../utils/log";

import { IProxyType } from "../types/deploymentVariables";

const deployProxyAdmin: (hre: HardhatRuntimeEnvironment, proxyType: IProxyType) => Promise<void> = async function (
    hre: HardhatRuntimeEnvironment,
    proxyType: IProxyType,
) {
    const { proxyDeployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;
    const { name } = hre.network;
    const networkType = conceroNetworks[name].type;

    const initialOwner = getWallet(networkType, "proxyDeployer", "address");
    const gasPrice = await hre.ethers.provider.getGasPrice();
    const maxFeePerGas = gasPrice.mul(2); // Set it to twice the base fee
    const maxPriorityFeePerGas = hre.ethers.utils.parseUnits("2", "gwei"); // Set a priority fee

    // log("Deploying...", `deployProxyAdmin: ${proxyType}`, name);
    const deployProxyAdmin = (await deploy("ConceroProxyAdmin", {
        from: proxyDeployer,
        args: [initialOwner],
        log: true,
        autoMine: true,
        skipIfAlreadyDeployed: false,
        // maxFeePerGas,
        // maxPriorityFeePerGas,
        gasLimit: writeContractConfig.gas,
    })) as Deployment;

    log(`Deployed at: ${deployProxyAdmin.address}`, `deployProxyAdmin: ${proxyType}`, name);
    updateEnvAddress(`${proxyType}Admin`, name, deployProxyAdmin.address, `deployments.${networkType}`);
};

export default deployProxyAdmin;
deployProxyAdmin.tags = ["ConceroProxyAdmin"];
