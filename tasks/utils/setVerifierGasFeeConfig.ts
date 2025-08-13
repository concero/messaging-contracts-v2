import { gasFeeConfigVerifier } from "../../constants/gasConfig";
import {
	ConceroHardhatNetwork,
	ConceroLocalNetwork,
	ConceroNetwork,
} from "../../types/ConceroNetwork";
import { getFallbackClients, log } from "../../utils";

export type AnyNetwork = ConceroNetwork | ConceroLocalNetwork | ConceroHardhatNetwork;

type SetVerifierGasFeeConfigArgs = {
	vrfMsgReportRequestGasOverhead: number;
	clfGasPriceOverEstimationBps: number;
	clfCallbackGasOverhead: number;
	clfCallbackGasLimit: number;
};

export async function setVerifierGasFeeConfig(
	network: AnyNetwork,
	verifierAddress: string,
	overrideArgs?: Partial<SetVerifierGasFeeConfigArgs>,
) {
	const { abi } = await import(
		"../../artifacts/contracts/ConceroVerifier/ConceroVerifier.sol/ConceroVerifier.json"
	);

	const { publicClient, walletClient } = getFallbackClients(network);

	try {
		const defaultArgs: SetVerifierGasFeeConfigArgs = {
			vrfMsgReportRequestGasOverhead: gasFeeConfigVerifier.vrfMsgReportRequestGasOverhead,
			clfGasPriceOverEstimationBps: gasFeeConfigVerifier.clfGasPriceOverEstimationBps,
			clfCallbackGasOverhead: gasFeeConfigVerifier.clfCallbackGasOverhead,
			clfCallbackGasLimit: gasFeeConfigVerifier.clfCallbackGasLimit,
		};

		const args: SetVerifierGasFeeConfigArgs = {
			...defaultArgs,
			...overrideArgs,
		};

		log(
			`Setting verifier gas fee config on chainId ${network.chainId}: vrfMsgReportRequestGasOverhead=${args.vrfMsgReportRequestGasOverhead}, clfGasPriceOverEstimationBps=${args.clfGasPriceOverEstimationBps}, clfCallbackGasOverhead=${args.clfCallbackGasOverhead}, clfCallbackGasLimit=${args.clfCallbackGasLimit}`,
			"setVerifierGasFeeConfig",
			network.name,
		);

		const setGasFeeConfigHash = await walletClient.writeContract({
			account: walletClient.account!,
			address: verifierAddress as `0x${string}`,
			abi: abi,
			functionName: "setGasFeeConfig",
			args: [
				args.vrfMsgReportRequestGasOverhead,
				args.clfGasPriceOverEstimationBps,
				args.clfCallbackGasOverhead,
				args.clfCallbackGasLimit,
			],
			chain: undefined,
		});

		const setGasFeeConfigStatus = (
			await publicClient.waitForTransactionReceipt({
				hash: setGasFeeConfigHash,
			})
		).status;

		if (setGasFeeConfigStatus === "success") {
			log(
				`Verifier gas fee config set successfully. Hash: ${setGasFeeConfigHash}`,
				"setVerifierGasFeeConfig",
				network.name,
			);
		} else {
			log(
				`Set verifier gas fee config reverted: ${setGasFeeConfigHash}`,
				"setVerifierGasFeeConfig",
				network.name,
			);
		}
	} catch (error) {
		log(
			`Error setting verifier gas fee config: ${(error as Error).message}`,
			"setVerifierGasFeeConfig",
			network.name,
		);
	}
}
