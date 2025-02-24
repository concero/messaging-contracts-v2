import { execSync } from "child_process";
import { Address, Hash } from "viem";

function getMessageCLFReportResponse({
    requester,
    requestId,
    internalMessageConfig,
    messageHashSum,
    srcChainData,
    allowedOperators,
}: {
    requester: Address;
    requestId: Hash;
    internalMessageConfig: string;
    messageHashSum: string;
    srcChainData: string;
    allowedOperators: string[];
}) {
    try {
        const formattedAllowedOperators = allowedOperators.length
            ? `[${allowedOperators.map(op => `"${op}"`).join(",")}]`
            : "[]";

        const messageReportResponseBytes = execSync(
            `make script "args=test/foundry/scripts/MockCLFReport/MessageReport.sol --sig 'getResponse(address,bytes32,bytes32,bytes32,bytes,bytes[])' ${
                requester
            } ${internalMessageConfig} ${requestId} ${messageHashSum} ${`"${srcChainData}"`} ${
                formattedAllowedOperators
            } --json"`,
        ).toString();

        const jsonStart = messageReportResponseBytes.indexOf("{");
        const jsonStr = messageReportResponseBytes.slice(jsonStart);
        const result = JSON.parse(jsonStr);

        console.log(result.returned);

        const rawBytes = result.returned;

        return rawBytes;
    } catch (error) {
        console.error("Error running MessageReport script:", error);
        throw error;
    }
}

export { getMessageCLFReportResponse };
