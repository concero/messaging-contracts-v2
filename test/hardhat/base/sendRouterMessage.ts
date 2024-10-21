import { IConceroMessageRequest } from "../utils/types";
import { ConceroNetwork } from "../../../types/ConceroNetwork";
import { getEnvAddress, getFallbackClients } from "../../../utils";
import { viemReceiptConfig } from "../../../constants";

export interface SendRouterMessageReturnType {
    hash: string;
    logs: any;
}

export async function sendRouterMessage(
    chain: ConceroNetwork,
    message: IConceroMessageRequest,
    value?: bigint,
): Promise<SendRouterMessageReturnType> {
    const { abi: conceroRouterAbi } = await import(
        "../../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
    );

    const { walletClient, publicClient } = getFallbackClients(chain);
    const [conceroRouterAddress] = getEnvAddress("routerProxy", chain.name);

    // const { request } = await publicClient.simulateContract({
    //     account: walletClient.account,
    //     abi: conceroRouterAbi,
    //     address: conceroRouterAddress,
    //     functionName: "sendMessage",
    //     args: [message],
    //     chain: chain.viemChain,
    //     value,
    // });

    console.log(`Sending message to ${chain.name}...`);
    const hash = await walletClient.writeContract({
        account: walletClient.account,
        abi: conceroRouterAbi,
        address: conceroRouterAddress,
        functionName: "sendMessage",
        args: [message],
        value,
    });
    console.log(hash);
    const { status, logs } = await publicClient.waitForTransactionReceipt({ hash, ...viemReceiptConfig });

    if (status !== "success") {
        throw new Error(`Failed to send message: ${hash}`);
    }

    console.log(`Message sent: ${hash}`);

    return { hash, logs };
}
