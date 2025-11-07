import { Runtime } from "@chainlink/cre-sdk";
import { sha256 } from "viem";

import { GlobalContext } from "../types";
import { chainsOptions, networksOptions } from "./chainOptions";

export const validateConfigs = (runtime: Runtime<GlobalContext>): void => {
    const originalChainsChecksum = runtime.getSecret({id: 'CHAINS_CONFIG_HASHSUM'}).result().value
    const originalNetworksChecksum = runtime.getSecret({id: 'NETWORKS_CONFIG_HASHSUM'}).result().value

    const currentCheckSum = sha256(Buffer.from(JSON.stringify(chainsOptions)))
    if (currentCheckSum === originalChainsChecksum){
        throw new Error('Invalid chains checksum');
    }

    const networkCheckSum = sha256(Buffer.from(JSON.stringify(networksOptions)))
    if (networkCheckSum === originalNetworksChecksum){
        throw new Error('Invalid networks checksum');
    }
}