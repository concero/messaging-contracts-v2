import { Runtime } from "@chainlink/cre-sdk";

import { DomainError, ErrorCode, GlobalConfig } from "../helpers";

export const validateMessageVersion = (version: number, runtime: Runtime<GlobalConfig>): void => {
	if (!runtime.config.allowedMessageVersions.includes(version)) {
		throw new DomainError(ErrorCode.CONFIG_INVALID_VERSION, "Message version is not valid");
	}
};
