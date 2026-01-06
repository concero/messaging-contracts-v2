import { Address, Hex } from "viem";

import { DecodedMessageSentReceipt } from "../helpers";

export namespace MessagingCodec {
	export function decodeReceipt(input: string): DecodedMessageSentReceipt {
		const hex = input.startsWith("0x") ? input.slice(2) : input;
		let offset = 0;

		const readHex = (bytes: number) => {
			const s = hex.slice(offset, offset + bytes * 2);
			offset += bytes * 2;
			return s;
		};

		const readUInt = (bytes: number) => parseInt(readHex(bytes), 16);

		const readBigInt = (bytes: number) => BigInt("0x" + readHex(bytes));

		const readAddress = (): Address => `0x${readHex(20)}`;

		// parsing

		const version = readUInt(1);
		const srcChainSelector = readUInt(3);
		const dstChainSelector = readUInt(3);
		const nonce = readBigInt(32);

		// src chain data
		const srcLen = readUInt(3);
		const sender = readAddress();
		const blockConfirmations = readBigInt(8);

		// dst chain data
		const dstLen = readUInt(3);
		const dstData = readHex(dstLen);

		let dstReceiver: Address | null = null;
		let dstGasLimit: number | null = null;

		if (dstLen === 24) {
			dstReceiver = `0x${dstData.slice(0, 40)}`; // 20 bytes
			dstGasLimit = parseInt(dstData.slice(40), 16); // last 4 bytes
		} else {
			throw new Error("Dst type not supported");
		}

		// relayer lib
		const relayerLen = readUInt(3);
		const relayerLib: Hex = `0x${readHex(relayerLen)}`;

		// validator libs
		const validatorCount = readUInt(3);
		const validatorLibs: Hex[] = [];
		const internalValidatorConfigs: Hex[] = [];

		for (let i = 0; i < validatorCount; i++) {
			const L = readUInt(3);
			validatorLibs.push(`0x${readHex(L)}`);
		}

		for (let i = 0; i < validatorCount; i++) {
			const L = readUInt(3);
			internalValidatorConfigs.push(`0x${readHex(L)}`);
		}

		// payload
		const payloadLen = readUInt(3);
		const payload: Hex = `0x${readHex(payloadLen)}`;

		return {
			version,
			srcChainSelector,
			dstChainSelector,
			nonce,
			srcChainData: {
				sender,
				blockConfirmations,
			},
			dstChainData: {
				raw: `0x${dstData}`,
				receiver: dstReceiver,
				gasLimit: dstGasLimit,
			},
			relayerLib,
			validatorLibs,
			internalValidatorConfigs,
			payload,
		};
	}
}
