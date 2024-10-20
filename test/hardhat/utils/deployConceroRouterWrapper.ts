import hre from "hardhat";

export const deployConceroRouterWrapper = async (): Promise<string> => {
    const deployment = await deployConceroRouterWrapper(hre);
    return deployment.address;
};
