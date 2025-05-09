import { execSync } from "child_process";

import type { Address } from "viem";

import { getEnvVar } from "../../utils";

export function getCLFReport(response: string, requestId: string, client: Address): string {
	try {
		const subscriptionId = getEnvVar("CLF_SUBID_LOCALHOST");
		const command = `make script "args=test/foundry/scripts/MockCLFReport/BaseMockCLFReport.sol --sig 'createMockClfReport(bytes, bytes32, address, uint64)' ${response} ${requestId} ${client} ${subscriptionId} --json"`;

		const reportBytes = execSync(command).toString();
		const jsonStart = reportBytes.indexOf("{");
		const jsonStr = reportBytes.slice(jsonStart);

		const result = JSON.parse(jsonStr);

		return result.returned;
	} catch (error) {
		console.error("Error running getReport script:", error);
		throw error;
	}
}
