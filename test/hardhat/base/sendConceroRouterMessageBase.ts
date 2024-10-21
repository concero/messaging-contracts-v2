import { IConceroMessageRequest } from "../utils/types";

export interface ISendConceroRouterMessageBase {
    conceroRouterAddress: string;
    message: IConceroMessageRequest;
    walletClient: any;
    publicClient: any;
}

export const sendConceroRouterMessageBase = async ({
    conceroRouterAddress,
    message,
    walletClient,
    publicClient,
}: ISendConceroRouterMessageBase) => {
    const { abi: conceroRouterAbi } = await import(
        "../../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
    );

    const request = await publicClient.simulateContract({
        account: walletClient.account,
        abi: conceroRouterAbi,
        address: conceroRouterAddress,
        functionName: "sendMessage",
        args: [message],
    });

    const hash = await walletClient.writeContract(request);
    const { status, logs } = await publicClient.waitForTransactionReceipt({ hash });

    if (status !== "success") {
        throw new Error(`Failed to send message: ${hash}`);
    }

    console.log(`Message sent: ${hash}`);

    return { hash, logs };
};
