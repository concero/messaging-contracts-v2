import { execSync } from "child_process";
import { Address, Hash } from "viem";

function getMessageCLFReportResponse({
	requester,
	internalMessageConfig,
	messageId,
	messageHashSum,
	srcChainData,
	allowedOperators,
}: {
	requester: Address;
	requestId: Hash;
	internalMessageConfig: string;
	messageId: Hash;
	messageHashSum: string;
	srcChainData: string;
	allowedOperators: string[];
}) {
	try {
		const formattedAllowedOperators = allowedOperators.length
			? `[${allowedOperators.map(op => `"${op}"`).join(",")}]`
			: "[]";

		const command = `make script "args=test/foundry/scripts/MockCLFReport/MessageReport.sol --sig 'getResponse(address,bytes32,bytes32,bytes32,bytes,bytes[])' ${
			requester
		} ${internalMessageConfig} ${messageId} ${messageHashSum} ${`"${srcChainData}"`} ${
			formattedAllowedOperators
		} --json"`;

		const messageReportResponseBytes = execSync(command).toString();

		const jsonStart = messageReportResponseBytes.indexOf("{");
		const jsonStr = messageReportResponseBytes.slice(jsonStart);
		const result = JSON.parse(jsonStr);

		const rawBytes = result.returns[0].value;

		return rawBytes;
	} catch (error) {
		console.error("Error running MessageReport script:", error);
		throw error;
	}
}

export { getMessageCLFReportResponse };
