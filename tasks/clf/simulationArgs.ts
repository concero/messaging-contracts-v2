import { type Address } from "viem";

type ArgBuilder = () => Promise<string[]>;

const getSimulationArgs: { [functionName: string]: ArgBuilder } = {
	operatorRegistration: async () => {
		const unusedHash = "0x0";
		const chainTypes = [0, 1, 2]; // Example chain types
		const actions = [0, 0, 0]; // All REGISTER actions
		const operatorAddresses: Address[] = [
			"0x70E73f067a1fC9FE6D53151bd271715811746d3a",
			"0x8431717927C4a3343bCf1626e7B5B1D31E240406",
			"0x9565c2036963697786705edge14C35e0C31fF4989",
		];
		const operatorAddress = "0x70E73f067a1fC9FE6D53151bd271715811746d3a";

		const chainTypesHex = `0x${Buffer.from(chainTypes).toString("hex")}`;
		const actionsHex = `0x${Buffer.from(actions).toString("hex")}`;
		const operatorAddressesHex = `0x000000000000000000000000${operatorAddresses.map(addr => addr.slice(2)).join("")}`;

		return [unusedHash, chainTypesHex, actionsHex, operatorAddressesHex, operatorAddress];
	},

	messageReport: async () => {
		const unusedHash = "0x0";
		const internalMessageConfig = "0x1234";
		const messageId = "0xf721b113e0a0401ba87f48aff9801c78f037cab36cb43c72bd115ccec7845d27";
		const messageHashSum = "0x064f6190edeced1d56cad0917491d69e28e6983908e20da84151f09a56db5654";
		const srcChainData = "0x5678";
		const operatorAddress = "0x70E73f067a1fC9FE6D53151bd271715811746d3a";

		return [
			unusedHash,
			internalMessageConfig,
			messageId,
			messageHashSum,
			srcChainData,
			operatorAddress,
		];
	},
};

export { getSimulationArgs };
