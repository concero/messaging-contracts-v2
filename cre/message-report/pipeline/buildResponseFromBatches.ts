import { Report, Runtime } from "@chainlink/cre-sdk";

import { GlobalConfig } from "../helpers";

type ResponseItem = {
	rawReport: string;
	reportContext: string;
	signs: {
		signature: string;
		signerId: number;
	}[];
};

export const buildResponseFromBatches = (
	runtime: Runtime<GlobalConfig>,
	batches: { report: ReturnType<Report["x_generatedCodeOnly_unwrap"]>; messageId: string }[],
): Record<string, ResponseItem> => {
	const responseBody: { [messageId: string]: ResponseItem } = {};

	batches.forEach(batch => {
		responseBody[batch.messageId] = {
			rawReport: Buffer.from(batch.report.rawReport).toString("hex"),
			signs: batch.report.sigs.map(i => ({
				signature: Buffer.from(i.signature).toString("hex"),
				signerId: i.signerId,
			})),
			reportContext: Buffer.from(batch.report.reportContext).toString("hex"),
		};
	});

	return responseBody;
};
