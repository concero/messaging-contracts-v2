import { MessagingDeploymentManager } from "@concero/v2-operators/src/common/managers/MessagingDeploymentManager";
import { Address, Hash, encodePacked, zeroHash } from "viem";

import { EvmSrcChainData } from "../../clf/src/messageReport/types";
import { simulateCLFScript } from "../../tasks/clf";

export async function getMessageCLFReportResponse({
	messageId,
	messageHash,
	srcChainSelector,
	srcChainData,
	operatorAddresses,
}: {
	messageId: Hash;
	messageHash: Hash;
	srcChainSelector: number;
	srcChainData: EvmSrcChainData;
	operatorAddresses: Address;
}) {
	try {
		const deploymentsManager = MessagingDeploymentManager.getInstance();
		const res = await simulateCLFScript(
			__dirname + "/../../clf/dist/messageReport.js",
			[
				zeroHash,
				encodePacked(["uint24"], [Number(srcChainSelector)]),
				messageId,
				messageHash,
				srcChainData,
				operatorAddresses,
			],
			{
				CONCERO_VERIFIER_LOCALHOST: await deploymentsManager.getConceroVerifier(),
			},
		);

		if (res?.errorString) {
			return res;
		}

		return res?.responseBytesHexstring;
	} catch (error) {
		console.error("Error running MessageReport script:", error);
		throw error;
	}
}
