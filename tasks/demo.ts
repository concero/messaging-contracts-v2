import { task } from "hardhat/config";
import { setVariables as setConceroRouterVariables } from "./deployCLFRouter/setVariables";
import { setVariables as setCLFRouterVariables } from "./deployConceroRouter/setVariables";
import deployCLFRouter from "../deploy/CLFRouter";
import deployConceroRouter from "../deploy/ConceroRouter";

task("deploy-infra", "Deploy contracts").setAction(async (_, hre) => {
    await deployCLFRouter(hre);
    await setCLFRouterVariables(hre);

    await deployConceroRouter(hre);
    await setConceroRouterVariables(hre);
});
