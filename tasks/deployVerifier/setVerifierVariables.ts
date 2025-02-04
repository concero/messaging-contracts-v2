import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { conceroNetworks } from "../../constants";
import { ConceroNetworkNames } from "../../types/ConceroNetwork";

async function setVerifierVariables(hre: HardhatRuntimeEnvironment) {
    const { live, name } = hre.network;
    const network = conceroNetworks[name as ConceroNetworkNames];
}

export { setVerifierVariables };
