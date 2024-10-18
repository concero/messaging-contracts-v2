// import { ethers } from "hardhat";
// import { conceroNetworks } from "../../../constants";
// import { ConceroNetworkNames } from "../../../types/ConceroNetwork";
//
// export const switchFork = async (chainName: ConceroNetworkNames) => {
//     const { forking } = conceroNetworks[chainName];
//     if (!forking) {
//         throw new Error("Forking is not defined");
//     }
//
//     await ethers.provider.send("hardhat_reset", [{ forking }]);
// };
