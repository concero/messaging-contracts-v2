import hre from "hardhat";
import deployConceroRouter from "../../../deploy/ConceroRouter";

export const deployConceroRouterWrapper = async (): Promise<string> => {
    const deployment = await deployConceroRouter(hre);
    return deployment.address;
};
