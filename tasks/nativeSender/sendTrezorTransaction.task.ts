import { task, types } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import {
	conceroNetworks,
	getFallbackClients,
	log,
	trezorSendTx,
} from "@concero/contract-utils";
import { Address, Hex, isAddress, isHex, parseEther } from "viem";

type TrezorTransactionTaskArgs = {
	contract: string;
	data: string;
	value?: string;
	gas?: string;
	nonce?: string;
	gasprice?: string;
	maxfeepergas?: string;
	maxpriorityfeepergas?: string;
	trezorpath?: string;
	forcelegacy?: boolean;
};

type TrezorTransactionParams = {
	to: Address;
	data: Hex;
	value: bigint;
	gas?: bigint;
	nonce?: number;
	gasPrice?: bigint;
	maxFeePerGas?: bigint;
	maxPriorityFeePerGas?: bigint;
};

function normalizeTransactionData(data: string): Hex {
	const normalized = data.startsWith("0x") ? data : `0x${data}`;
	if (!isHex(normalized)) throw new Error("Transaction data must be hex");

	return normalized;
}

function parseOptionalBigInt(value: string | undefined, name: string): bigint | undefined {
	if (!value) return undefined;
	try {
		return BigInt(value);
	} catch {
		throw new Error(`${name} must be an integer amount in wei`);
	}
}

function parseOptionalNonce(value: string | undefined): number | undefined {
	if (!value) return undefined;

	const nonce = Number(value);
	if (!Number.isInteger(nonce) || nonce < 0) throw new Error("nonce must be a non-negative integer");

	return nonce;
}

export function buildTrezorTransactionParams(
	taskArgs: TrezorTransactionTaskArgs,
): TrezorTransactionParams {
	if (!isAddress(taskArgs.contract)) throw new Error("contract must be a valid address");

	const gas = parseOptionalBigInt(taskArgs.gas, "gas");
	const nonce = parseOptionalNonce(taskArgs.nonce);
	const gasPrice = parseOptionalBigInt(taskArgs.gasprice, "gasprice");
	const maxFeePerGas = parseOptionalBigInt(taskArgs.maxfeepergas, "maxfeepergas");
	const maxPriorityFeePerGas = parseOptionalBigInt(
		taskArgs.maxpriorityfeepergas,
		"maxpriorityfeepergas",
	);

	return {
		to: taskArgs.contract,
		data: normalizeTransactionData(taskArgs.data),
		value: taskArgs.value ? parseEther(taskArgs.value) : 0n,
		...(gas !== undefined && { gas }),
		...(nonce !== undefined && { nonce }),
		...(gasPrice !== undefined && { gasPrice }),
		...(maxFeePerGas !== undefined && { maxFeePerGas }),
		...(maxPriorityFeePerGas !== undefined && { maxPriorityFeePerGas }),
	};
}

export async function sendTrezorTransaction(
	taskArgs: TrezorTransactionTaskArgs,
	hre: HardhatRuntimeEnvironment,
) {
	const chain = conceroNetworks[hre.network.name];
	if (!chain) throw new Error(`Unsupported network: ${hre.network.name}`);

	const { publicClient } = getFallbackClients(chain);
	const txParams = buildTrezorTransactionParams(taskArgs);

	const hash = await trezorSendTx(
		{ publicClient },
		txParams,
		{
			path: taskArgs.trezorpath ?? "m/44'/60'/0'/0/0",
			showFromAddressOnTrezor: true,
			forceLegacy: taskArgs.forcelegacy ?? false,
		},
	);

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(`${status}: ${hash}`, "sendTrezorTransaction", hre.network.name);
}

const sendTrezorTransactionTask = task(
	"send-trezor-transaction",
	"Send an arbitrary transaction using Trezor",
)
	.addParam("contract", "Target contract address")
	.addParam("data", "Transaction calldata, with or without 0x prefix")
	.addOptionalParam("value", "Native value to send in ETH", "0", types.string)
	.addOptionalParam("gas", "Gas limit override in wei", undefined, types.string)
	.addOptionalParam("nonce", "Nonce override", undefined, types.string)
	.addOptionalParam("gasprice", "Legacy gas price override in wei", undefined, types.string)
	.addOptionalParam("maxfeepergas", "EIP-1559 max fee per gas override in wei", undefined, types.string)
	.addOptionalParam(
		"maxpriorityfeepergas",
		"EIP-1559 max priority fee per gas override in wei",
		undefined,
		types.string,
	)
	.addOptionalParam("trezorpath", "Trezor derivation path", "m/44'/60'/0'/0/0", types.string)
	.addFlag("forcelegacy", "Force legacy gas pricing")
	.setAction(async (taskArgs, hre) => {
		await sendTrezorTransaction(taskArgs, hre);
	});

export default sendTrezorTransactionTask;
