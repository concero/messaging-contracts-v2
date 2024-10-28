import { IConceroMessageRequest } from "../utils/types";
import { ConceroNetwork } from "../../../types/ConceroNetwork";
import { getEnvAddress, getFallbackClients, log } from "../../../utils";
import { abi as routerAbi } from "../../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json";

export interface SendRouterMessageReturnType {
    hash: string;
    logs: any;
}

export async function sendRouterMessage(
    chain: ConceroNetwork,
    message: IConceroMessageRequest,
    value?: bigint,
): Promise<SendRouterMessageReturnType> {
    const { walletClient, publicClient } = getFallbackClients(chain);
    const [conceroRouterAddress] = getEnvAddress("routerProxy", chain.name);

    const { request } = await publicClient.simulateContract({
        account: walletClient.account,
        abi: routerAbi,
        address: conceroRouterAddress,
        functionName: "sendMessage",
        args: [message],
        chain: chain.viemChain,
        value,
    });

    const hash = await walletClient.writeContract(request);

    log(`Message sent with hash: ${hash}`, "sendRouterMessage", chain.name);
    // const { status, logs } = await publicClient.waitForTransactionReceipt({ hash, ...viemReceiptConfig });
    //
    // if (status !== "success") {
    //     throw new Error(`Failed to send message: ${hash}`);
    // }
    //
    // console.log(`Message sent: ${hash}`);

    return { hash };
}
