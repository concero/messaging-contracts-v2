import { execSync } from "child_process";

import { Address, Hash } from "viem";

function getMessageCLFReportResponse({
	requester,
	internalMessageConfig,
	messageId,
	messageHashSum,
	dstChainData,
	allowedOperators,
}: {
	requester: Address;
	requestId: Hash;
	internalMessageConfig: string;
	messageId: Hash;
	messageHashSum: string;
	dstChainData: string;
	allowedOperators: Address[];
}) {
	try {
		const encodedOperators = allowedOperators.map(addr => {
			// Remove 0x, pad to 64 chars (32 bytes), add 0x back
			return `0x000000000000000000000000${addr.slice(2)}`;
		});

		const formattedAllowedOperators = encodedOperators.length
			? `[${encodedOperators.join(",")}]`
			: "[]";

		const command = `make script "args=test/foundry/scripts/MockCLFReport/MessageReport.sol --sig 'getResponse(address,bytes32,bytes32,bytes32,bytes,bytes[])' ${
			requester
		} ${internalMessageConfig} ${messageId} ${messageHashSum} ${dstChainData} ${
			formattedAllowedOperators
		} --json"`;

		console.log("Running command:", command);

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
