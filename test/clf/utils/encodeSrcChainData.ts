import { Address, encodeAbiParameters } from "viem";

export function encodedSrcChainData(sender: Address, blockNumber: bigint) {
	return encodeAbiParameters(
		[
			{
				type: "tuple",
				components: [
					{ name: "sender", type: "address" },
					{ name: "blockNumber", type: "uint256" },
				],
			},
		],
		[
			{
				sender: sender,
				blockNumber: blockNumber,
			},
		],
	);
}
