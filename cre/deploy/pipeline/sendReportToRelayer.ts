import { consensusIdenticalAggregation, cre, HTTPSendRequester, ok, Report, Runtime } from "@chainlink/cre-sdk";

import { GlobalContext } from "../types";


export const sendReportToRelayer = (runtime: Runtime<GlobalContext>, report: Report): void => {
    const sendReportFetcher = (sendRequester: HTTPSendRequester, config: GlobalContext): { statusCode: number } => {
        const reportResult = report.x_generatedCodeOnly_unwrap()

        const bodyBytes = new TextEncoder().encode(JSON.stringify({
            rawReport: Buffer.from(reportResult.rawReport).toString('hex'),
            signs: reportResult.sigs.map(i => ({
                signature: Buffer.from(i.signature).toString('hex'),
                signerId: i.signerId,
            })),
            reportContext:  Buffer.from(reportResult.reportContext).toString('hex'),
        }))

        const resp = sendRequester.sendRequest({
            url: "https://webhook.site/1bf744e6-fb89-4ed5-ba57-912675a433a7",
            method: "POST" as const,
            body: Buffer.from(bodyBytes).toString("base64"),
            headers: {
                "Content-Type": "application/json",
            }
        }).result()

        if (!ok(resp)) {
            throw new Error(`HTTP request failed with status: ${resp.statusCode}`)
        }

        return { statusCode: resp.statusCode }
    }

    const httpClient = new cre.capabilities.HTTPClient()
    httpClient
        .sendRequest(
            runtime,
            sendReportFetcher,
            consensusIdenticalAggregation()
        )(runtime.config)
        .result()
}