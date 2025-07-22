import { ProxyEnum } from "../../constants";
import { gasFeeConfigVerifier } from "../../constants/gasConfig";
import {
	ConceroHardhatNetwork,
	ConceroLocalNetwork,
	ConceroNetwork,
} from "../../types/ConceroNetwork";
import { getEnvAddress, getFallbackClients, log } from "../../utils";

export type AnyNetwork = ConceroNetwork | ConceroLocalNetwork | ConceroHardhatNetwork;

export async function setVerifierGasFeeConfig(network: AnyNetwork) {
	const { abi } = await import(
		"../../artifacts/contracts/ConceroVerifier/ConceroVerifier.sol/ConceroVerifier.json"
	);

	const { publicClient, walletClient } = getFallbackClients(network);

	// Get the verifier contract address
	const [contractAddress] = getEnvAddress(ProxyEnum.verifierProxy, network.name);

	try {
		const vrfMsgReportRequestGasOverheadNum =
			gasFeeConfigVerifier.vrfMsgReportRequestGasOverhead;
		const clfGasPriceOverEstimationBpsNum = gasFeeConfigVerifier.clfGasPriceOverEstimationBps;
		const clfCallbackGasOverheadNum = gasFeeConfigVerifier.clfCallbackGasOverhead;
		const clfCallbackGasLimitNum = gasFeeConfigVerifier.clfCallbackGasLimit;

		log(
			`Setting verifier gas fee config on chainId ${network.chainId}: vrfMsgReportRequestGasOverhead=${vrfMsgReportRequestGasOverheadNum}, clfGasPriceOverEstimationBps=${clfGasPriceOverEstimationBpsNum}, clfCallbackGasOverhead=${clfCallbackGasOverheadNum}, clfCallbackGasLimit=${clfCallbackGasLimitNum}`,
			"setVerifierGasFeeConfig",
			network.name,
		);

		const setGasFeeConfigHash = await walletClient.writeContract({
			account: walletClient.account!,
			address: contractAddress,
			abi: abi,
			functionName: "setGasFeeConfig",
			args: [
				vrfMsgReportRequestGasOverheadNum,
				clfGasPriceOverEstimationBpsNum,
				clfCallbackGasOverheadNum,
				clfCallbackGasLimitNum,
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
