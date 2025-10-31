import { conceroRouters } from "./constants";
import { Utility } from "./utility";
import { getPublicClient, Fetcher } from "./client";


export async function main() {
    const args = Utility.decodeInputs(bytesArgs);
    const publicClient = getPublicClient(args.srcChainSelector.toString());

    const log = await Fetcher.fetchConceroMessage(
       publicClient,
       conceroRouters[Number(args['srcChainSelector'])],
       args.messageId,
       BigInt(args.srcChainData.blockNumber),
   )



    return log.transactionHash
}
