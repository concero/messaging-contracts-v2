import { encodeAbiParameters, zeroHash } from "viem";

import { OperatorRegistrationArgs } from "../../clf/src/operatorRegistration/types";
import { simulateCLFScript } from "../../tasks/clf";
import { getEnvVar } from "../../utils";
import { getCLFReport } from "./getCLFReport";

export async function getOperatorRegistrationCLFResponse(
	operatorRegistrationArgs: OperatorRegistrationArgs,
) {
	const clfSimulationResult = await simulateCLFScript(
		__dirname + "/../../clf/dist/operatorRegistration.js",
		[
			zeroHash,
			encodeAbiParameters([{ type: "uint8[]" }], [operatorRegistrationArgs.chainTypes]),
			encodeAbiParameters([{ type: "uint8[]" }], [operatorRegistrationArgs.actions]),
			encodeAbiParameters(
				[{ type: "address[]" }],
				[operatorRegistrationArgs.operatorAddresses],
			),
			operatorRegistrationArgs.requester,
		],
	);

	return getCLFReport(
		clfSimulationResult.responseBytesHexstring,
		zeroHash,
		getEnvVar("CONCERO_VERIFIER_PROXY_LOCALHOST"),
	);
}
