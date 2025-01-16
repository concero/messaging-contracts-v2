import { task } from "hardhat/config";
import { setVerifierVariables as setConceroRouterVariables } from "./deployVerifier/setVerifierVariables";
import { setVariables as setCLFRouterVariables } from "./deployRouter/setRouterVariables";
import deployVerifier from "../deploy/ConceroVerifier";
import deployRouter from "../deploy/ConceroRouter";

task("deploy-infra", "Deploy contracts").setAction(async (_, hre) => {
    await deployVerifier(hre);
    await setCLFRouterVariables(hre);

    await deployRouter(hre);
    await setConceroRouterVariables(hre);
});
