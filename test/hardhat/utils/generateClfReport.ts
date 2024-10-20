import { signMessage } from "viem/actions";
import { WalletClient } from "viem/clients/createWalletClient";
import { parseSignature } from "viem";

export async function generateClfReport(clfFulfillResponse: string, walletClient: WalletClient) {
    const signedMessage = await signMessage(walletClient, {
        message: clfFulfillResponse,
    });

    const parsedSignature = parseSignature(signedMessage);
    console.log(parsedSignature);
}
