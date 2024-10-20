import deployConceroRouter from "../../../deploy/ConceroRouter";

export const deployConceroRouterWrapper = async (): Promise<string> => {
    const hre = require("hardhat");
    const deployment = await deployConceroRouter(hre);
    return deployment.address;
};
