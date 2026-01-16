import { Report } from "@chainlink/cre-sdk";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { Hex } from "viem";

export interface IReport {
	rawReport: string;
	reportContext: string;
	signs: {
		signature: string;
		signerId: number;
	}[];
}

export interface IValidation {
	report: IReport;
	proofs: Record<Hex, Hex[]>;
}

export const buildValidation = (
	report: ReturnType<Report["x_generatedCodeOnly_unwrap"]>,
	messageIds: Hex[],
	merkleTree: StandardMerkleTree<Hex[]>,
): IValidation => {
	const validation: IValidation = {
		report: {
			rawReport: Buffer.from(report.rawReport).toString("hex"),
			signs: report.sigs.map(i => ({
				signature: Buffer.from(i.signature).toString("hex"),
				signerId: i.signerId,
			})),
			reportContext: Buffer.from(report.reportContext).toString("hex"),
		},
		proofs: {},
	};

	messageIds.forEach((messageId: Hex) => {
		validation.proofs[messageId] = merkleTree.getProof([messageId]) as Hex[];
	});

	return validation;
};
