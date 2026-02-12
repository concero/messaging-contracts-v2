import { creValidatorLibGasLimits, dstChainVerificationGasLimits } from "../constants";

export function getVerificationGasLimit(chainSelector: bigint): bigint {
	return (
		creValidatorLibGasLimits[Number(chainSelector)] ??
		dstChainVerificationGasLimits[Number(chainSelector)] ??
		dstChainVerificationGasLimits.default
	);
}
