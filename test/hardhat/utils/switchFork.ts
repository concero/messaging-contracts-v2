import { ethers } from "hardhat";
import { cNetworks } from "../../../constants";
import { CNetworkNames } from "../../../types/CNetwork";

export const switchFork = async (chainName: CNetworkNames) => {
    const { forking } = cNetworks[chainName];
    if (!forking) {
        throw new Error("Forking is not defined");
    }

    await ethers.provider.send("hardhat_reset", [{ forking }]);
};
