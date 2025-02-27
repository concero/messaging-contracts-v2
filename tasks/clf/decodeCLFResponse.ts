import { AbiParameter, decodeAbiParameters } from "viem";

const responseDecoders: { [key: string]: AbiParameter[] } = {
	operatorRegistration: [
		{ type: "uint8", name: "version" },
		{ type: "uint8", name: "reportType" },
		{ type: "address", name: "operator" },
		{ type: "uint32", name: "chainTypesLength" },
		{ type: "bytes", name: "chainTypes" },
		{ type: "uint32", name: "operatorsCount" },
		{ type: "address[]", name: "operatorAddresses" },
	],

	messageReport: [
		{ type: "uint8", name: "version" },
		{ type: "uint8", name: "reportType" },
		{ type: "uint8", name: "operatorLength" },
		{ type: "address", name: "operator" },
		{ type: "uint256", name: "internalMessageConfig" },
		{ type: "bytes32", name: "messageId" },
		{ type: "bytes32", name: "messageHashSum" },
		{ type: "uint32", name: "dstChainDataLength" },
		{ type: "bytes", name: "dstChainData" },
		{ type: "uint16", name: "operatorsCount" },
		{ type: "address[]", name: "allowedOperators" },
	],
};
/**
 * Decodes the response hex string based on the script name.
 * @param scriptName - The name of the script.
 * @param responseHex - The hex string response to decode.
 * @returns An object containing the decoded values.
 */
export function decodeCLFResponse(scriptName: string, responseHex: string): any {
	const decoder = responseDecoders[scriptName];
	if (!decoder) {
		console.error(`No decoder defined for script: ${scriptName}`);
		return null;
	}

	const responseData = responseHex.startsWith("0x") ? responseHex : "0x" + responseHex;

	try {
		const decodedValues = decodeAbiParameters(decoder, responseData);
		const result: Record<string, any> = {};

		decoder.forEach((param, index) => {
			result[param.name || `param${index}`] = decodedValues[index];
		});

		return result;
	} catch (error) {
		console.error("Failed to decode response:", error);
		return null;
	}
}
