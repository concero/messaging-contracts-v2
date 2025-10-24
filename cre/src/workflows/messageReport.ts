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
  type RequestJson,
} from "@chainlink/cre-sdk";
import { keccak256 } from "viem";
import cfg from "../../config.json" assert { type: "json" };
import { buildMessageReportBytes } from "../adapters/buildMessageReport";

interface Config { apiUrl: string; schedule: string; }
type MyResult = Record<string, never>;
interface SubmitResponse { success: boolean; }

const makeFormatter = (apiUrl: string) => (r: ReportResponse): RequestJson => ({
  url: apiUrl,
  method: "POST",
  body: Buffer.from(r.rawReport).toString("base64"),
  headers: {
    "Content-Type": "application/octet-stream",
    "X-Report-SeqNr": r.seqNr.toString(),
    "X-Report-Hash": keccak256(r.rawReport),
  },
  cacheSettings: { readFromCache: true, maxAgeMs: 60_000 },
});

const submitReportViaHTTP = (sendRequester: HTTPSendRequester, report: Report, apiUrl: string): SubmitResponse => {
  const res = sendRequester.sendReport(report, makeFormatter(apiUrl)).result();
  if (!ok(res)) throw new Error(`API returned error: status=${res.statusCode}`);
  return { success: true };
};

const onCronTrigger = (runtime: Runtime<Config>): MyResult => {
  const { apiUrl } = cfg as Config;

  const payload = runtime.runAsync(buildMessageReportBytes).result(); // Uint8Array

  const report = runtime.report({
    encodedPayload: hexToBase64(payload),
    encoderName: "evm",
    signingAlgo: "ecdsa",
    hashingAlgo: "keccak256",
  }).result();

  const http = new cre.capabilities.HTTPClient();
  http.sendRequest(
    runtime,
    (rq: HTTPSendRequester) => submitReportViaHTTP(rq, report, apiUrl),
    consensusIdenticalAggregation<SubmitResponse>()
  )().result();

  return {};
};

export async function main() {
  const runner = await Runner.newRunner<Config>();
  await runner.run((config: Config) => {
    const cron = new cre.capabilities.CronCapability();
    return [cre.handler(cron.trigger({ schedule: cfg.schedule }), onCronTrigger)];
  });
}
