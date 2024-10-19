import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { conceroNetworks, networkEnvKeys } from "../constants";
import updateEnvVariable from "../utils/updateEnvVariable";
import log from "../utils/log";
import { getClients, getEnvVar } from "../utils";

const deployConceroRouter: (hre: HardhatRuntimeEnvironment) => Promise<Deployment> = async function (
    hre: HardhatRuntimeEnvironment,
) {
    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;
    const { name, live } = hre.network;
    const networkType = conceroNetworks[name].type;

    console.log("Deploying...", "deployConceroRouter", name);

    const args = {
        usdc: getEnvVar(`USDC_${networkEnvKeys[name]}`),
        chainSelector: getEnvVar(`CL_CCIP_CHAIN_SELECTOR_${networkEnvKeys[name]}`),
        signer_0: getEnvVar(`CLF_DON_SIGNING_KEY_0_${networkEnvKeys[name]}`),
        signer_1: getEnvVar(`CLF_DON_SIGNING_KEY_0_${networkEnvKeys[name]}`),
        signer_2: getEnvVar(`CLF_DON_SIGNING_KEY_0_${networkEnvKeys[name]}`),
    };

    console.log("args:", args);

    const { publicClient } = getClients(conceroNetworks[name].viemChain);
    const gasPrice = String(await publicClient.getGasPrice());

    const conceroRouterDeploy = (await deploy("ConceroRouter", {
        from: deployer,
        args: [args.usdc, args.chainSelector, args.signer_0, args.signer_1, args.signer_2],
        log: true,
        autoMine: true,
        gasPrice,
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
