export namespace ConceroMessageSentEvent {
	export const name = "ConceroMessageSent";
	export const inputs = [
		{
			indexed: true,
			internalType: "bytes32",
			name: "messageId",
			type: "bytes32",
		},
		{
			indexed: false,
			internalType: "bytes",
			name: "messageReceipt",
			type: "bytes",
		},
		{
			indexed: false,
			internalType: "address[]",
			name: "validatorLibs",
			type: "address[]",
		},
		{
			indexed: false,
			internalType: "address",
			name: "relayerLib",
			type: "address",
		},
	];
}
