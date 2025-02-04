import deployRouter from "../../../deploy/ConceroRouter";

export const deployConceroRouterWrapper = async (): Promise<string> => {
    const hre = require("hardhat");
    const deployment = await deployRouter(hre);
    return deployment.address;
};
