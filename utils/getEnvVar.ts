import process from "process";

import { Address } from "viem";

import { envPrefixes, networkEnvKeys } from "../constants";
import { ConceroNetworkNames } from "../types/ConceroNetwork";
import { EnvPrefixes } from "../types/deploymentVariables";
import { type env } from "../types/env";
import { shorten } from "./formatting";

function getEnvVar(key: keyof env): string {
	const value = process.env[key];
	if (value === undefined) throw new Error(`Missing required environment variable ${key}`);
	if (value === "") throw new Error(`${key} must not be empty`);
	return value;
}

function getEnvAddress(
	prefix: keyof EnvPrefixes,
	networkName?: ConceroNetworkNames | string,
): [Address, string] {
	const searchKey = networkName
		? `${envPrefixes[prefix]}_${networkEnvKeys[networkName]}`
		: envPrefixes[prefix];
	const value = getEnvVar(searchKey) as Address;
	const friendlyName = `${prefix}(${shorten(value)})`;

	return [value, friendlyName];
}

export { getEnvVar, getEnvAddress };
