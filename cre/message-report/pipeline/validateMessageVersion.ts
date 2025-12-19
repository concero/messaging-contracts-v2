import { Runtime } from "@chainlink/cre-sdk";

import { DomainError, ErrorCode, GlobalConfig } from "../helpers";

export const validateMessageVersion = (version: number, runtime: Runtime<GlobalConfig>): void => {
	const allowedVersions = [1];
	/*    runtime
		.getSecret({ id: "ALLOWED_MESSAGE_VERSIONS" })
		.result()
		.value.split(",")
		.map(i => Number(i.trim()));*/

	if (!allowedVersions.includes(version)) {
		throw new DomainError(ErrorCode.CONFIG_INVALID_VERSION, "Message version is not valid");
	}
};
