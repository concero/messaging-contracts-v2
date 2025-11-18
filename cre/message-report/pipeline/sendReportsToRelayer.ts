import {consensusIdenticalAggregation, cre, Report, Runtime} from "@chainlink/cre-sdk";

import {CRE, GlobalConfig} from "../helpers";


type ReportBatch = {
  rawReport: string
    reportContext: string
  signs: {signature: string, signerId: number}[]
}

export const sendReportsToRelayer = (runtime: Runtime<GlobalConfig>, reports: Report[]): void => {
    const batches: ReportBatch[] = reports.map(report => {
        const reportResult = report.x_generatedCodeOnly_unwrap();
        return {
            rawReport: Buffer.from(reportResult.rawReport).toString("hex"),
            signs: reportResult.sigs.map(i => ({
                signature: Buffer.from(i.signature).toString("hex"),
                signerId: i.signerId,
            })),
            reportContext: Buffer.from(reportResult.reportContext).toString("hex"),
        }
    })

	const fetcher = CRE.buildFetcher(runtime, {
		url: "https://webhook.site/1bf744e6-fb89-4ed5-ba57-912675a433a7",
		method: "POST",
		body: {
             batches
        }, 
		headers: {
			"Content-Type": "application/json",
		},
	});
	const httpClient = new cre.capabilities.HTTPClient();

	httpClient
		.sendRequest(runtime, fetcher, consensusIdenticalAggregation())(runtime.config)
		.result();
};
