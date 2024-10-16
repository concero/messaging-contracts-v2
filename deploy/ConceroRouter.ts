import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import cNetworks, { networkEnvKeys } from "../constants/cNetworks";
import updateEnvVariable from "../utils/updateEnvVariable";
import log from "../utils/log";
import { getEnvVar } from "../utils";

const deployConceroRouter: (hre: HardhatRuntimeEnvironment) => Promise<Deployment> = async function (
    hre: HardhatRuntimeEnvironment,
) {
    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;
    const { name, live } = hre.network;
    const networkType = cNetworks[name].type;

    console.log("Deploying...", "deployConceroRouter", name);

    const defaultArgs = {
        usdc: getEnvVar(`USDC_${networkEnvKeys[name]}`),
    };

    const args = { ...defaultArgs };

    const conceroRouterDeploy = (await deploy("ConceroRouter", {
        from: deployer,
        args: [args.usdc],
        log: true,
        autoMine: true,
    })) as Deployment;

    log(`Deployed at: ${conceroRouterDeploy.address}`, "deployConceroRouter", name);
    if (live) {
        updateEnvVariable(
            `CONCERO_ROUTER_${networkEnvKeys[name]}`,
            conceroRouterDeploy.address,
            `deployments.${networkType}`,
        );
    }
    return conceroRouterDeploy;
};

export default deployConceroRouter;
deployConceroRouter.tags = ["ConceroRouter"];
