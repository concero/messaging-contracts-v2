import {
  cre,
  Runner,
  consensusIdenticalAggregation,
  hexToBase64,
  ok,
  type Runtime,
  type HTTPSendRequester,
  type Report,
  type ReportResponse,
  type RequestJson
} from "@chainlink/cre-sdk";
import { keccak256 } from "viem";
import { buildOperatorRegistrationBytes } from "../adapters/buildOperatorRegistration";

interface Config { apiUrl: string; schedule: string; }
type MyResult = Record<string, never>;
interface SubmitResponse { success: boolean; }

const makeFormatter = (apiUrl: string) => (r: ReportResponse): RequestJson => ({
  url: apiUrl,
  method: "POST",
  body: Buffer.from(r.rawReport).toString("base64"),
  headers: {
    "Content-Type": "application/octet-stream",
    "Accept": "application/json",
    "X-Report-SeqNr": r.seqNr.toString(),
    "X-Report-Hash": keccak256(r.rawReport)
  },
  cacheSettings: { readFromCache: true, maxAgeMs: 60_000 }
});

const submitReportViaHTTP = (sendRequester: HTTPSendRequester, report: Report, apiUrl: string): SubmitResponse => {
  const resp = sendRequester.sendReport(report, makeFormatter(apiUrl)).result();
  if (!ok(resp)) {
    throw new Error(`API returned error: status=${resp.statusCode}`);
  }
  return { success: true };
};

const onCronTrigger = (runtime: Runtime<Config>): MyResult => {
  const cfg = runtime.getConfig();
  const payload = buildOperatorRegistrationBytes();

  const report = runtime
    .report({
      encodedPayload: hexToBase64(payload),
      encoderName: "evm",
      signingAlgo: "ecdsa",
      hashingAlgo: "keccak256"
    })
    .result();

  const httpClient = new cre.capabilities.HTTPClient();
  httpClient
    .sendRequest(
      runtime,
      (sendRequester: HTTPSendRequester) => submitReportViaHTTP(sendRequester, report, cfg.apiUrl),
      consensusIdenticalAggregation<SubmitResponse>()
    )()
    .result();

  return {};
};

export async function main() {
  const runner = await Runner.newRunner<Config>();
  await runner.run((config: Config) => {
    const cron = new cre.capabilities.CronCapability();
    return [cre.handler(cron.trigger({ schedule: config.schedule }), onCronTrigger)];
  });
}
