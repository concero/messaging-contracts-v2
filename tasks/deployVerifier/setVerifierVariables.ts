import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { getEnvAddress, getFallbackClients, getWallet, log } from "../../utils";
import { conceroNetworks } from "../../constants";
import { ConceroNetwork, ConceroNetworkNames } from "../../types/ConceroNetwork";

async function setVerifierVariables(hre: HardhatRuntimeEnvironment) {
    const { live, name } = hre.network;
    const network = conceroNetworks[name as ConceroNetworkNames];
}

export { setVerifierVariables };
