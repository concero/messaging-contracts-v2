import { createEnvAddressGetter } from "@concero/contract-utils";

import { envPrefixes } from "../constants/envPrefixes";

export const { getEnvAddress } = createEnvAddressGetter({
	prefixes: envPrefixes,
});
