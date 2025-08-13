import { getNetworkEnvKey } from "@concero/contract-utils";
import process from "process";
import { Address } from "viem";

import { envPrefixes } from "../constants";
import { ConceroNetworkNames } from "../types/ConceroNetwork";
import { EnvPrefixes } from "../types/deploymentVariables";
import { type env } from "../types/env";
import { shorten } from "./formatting";
import { warn } from "./log";

function getEnvVar(key: keyof env): string | undefined {
	const value = process.env[key];
	if (value === undefined || value === "") {
		warn(`Missing env variable: ${key}`, "getEnvVar");
		return undefined;
	}

	return value;
}

function getEnvAddress(
	prefix: keyof EnvPrefixes,
	networkName?: ConceroNetworkNames | string,
): [Address, string] {
	const searchKey = networkName
		? `${envPrefixes[prefix]}_${getNetworkEnvKey(networkName)}`
		: envPrefixes[prefix];
	const value = getEnvVar(searchKey) as Address;
	const friendlyName = `${prefix}(${shorten(value)})`;

	return [value, friendlyName];
}

export { getEnvVar, getEnvAddress };
