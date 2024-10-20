import { signMessage } from "viem/actions";
import { WalletClient } from "viem/clients/createWalletClient";
import { parseSignature, zeroHash } from "viem";

export interface IClfReportSubmission {
    context: string[3];
    report: string;
    rs: string[];
    ss: string[];
    rawVs: string;
}

export async function generateClfReport(
    clfFulfillResponse: string,
    walletClient: WalletClient,
): Promise<IClfReportSubmission> {
    const signedMessage = await signMessage(walletClient, {
        message: clfFulfillResponse,
    });

    const parsedSignature = parseSignature(signedMessage);

    return {
        context: [zeroHash, zeroHash, zeroHash],
        report: zeroHash,
        rs: [parsedSignature.r],
        ss: [parsedSignature.s],
        rawVs: "0x" + parsedSignature.v?.toString(16),
    };
}
