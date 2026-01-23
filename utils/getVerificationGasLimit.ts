import { dstChainVerificationGasLimits } from "../constants/gasConfig";

export function getVerificationGasLimit(chainSelector: bigint): number {
	return (
		dstChainVerificationGasLimits[Number(chainSelector)] ??
		dstChainVerificationGasLimits.default
	);
}
