import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { getGasParameters, log } from "../utils";
/**
 * @notice Deploys the MockCLFRouter contract using Hardhat Deploy.
 * @param hre The Hardhat runtime environment.
 * @return The deployment object for the MockCLFRouter contract.
 */
async function deployMockCLFRouter(hre: HardhatRuntimeEnvironment): Promise<Deployment> {
    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;

    const deployment = await deploy("MockCLFRouter", {
        from: deployer,
        args: [],
        log: true,
        autoMine: true,
        skipIfAlreadyDeployed: true,
    });

    log(`Deployed at: ${deployment.address}`, "deployMockCLFRouter", hre.network.name);
    return deployment;
}

export default deployMockCLFRouter;
deployMockCLFRouter.tags = ["MockCLFRouter"];
