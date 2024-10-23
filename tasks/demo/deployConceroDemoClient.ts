import { task } from "hardhat/config";
import { compileContracts } from "../../utils";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import deployDemoClient from "../../deploy/ConceroDemoClient";

export async function deployConceroDemoClientTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
    compileContracts({ quiet: true });

    await deployDemoClient(hre);
}

task("deploy-demo-client", "Deploy the demo client contract").setAction(
    async (taskArgs, hre: HardhatRuntimeEnvironment) => {
        await deployConceroDemoClientTask(taskArgs, hre);
    },
);

export default {};
