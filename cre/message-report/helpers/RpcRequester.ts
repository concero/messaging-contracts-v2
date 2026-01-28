import { HTTPSendRequester, Runtime } from "@chainlink/cre-sdk";

import { ChainSelector } from "../systems";
import { headers } from "./constants";
import { CRE } from "./cre";
import { GlobalConfig } from "./types";
import { Utility } from "./utility";

export interface IRpcRequest {
	method: string;
	params: any;
	chainSelector: ChainSelector;
}

export type IRpcResponse = any | null;

export class RpcRequester {
	private readonly rpcs: Record<ChainSelector, string[]>;
	private requests: (CRE.IRequestOptions & { chainSelector: ChainSelector })[] = [];
	private reqCounter: number = 0;
	private readonly maxRetryCount = 15;
	private readonly asyncFetcher;

	constructor(
		rpcs: typeof this.rpcs,
		sendRequester: HTTPSendRequester,
		private readonly runtime: Runtime<GlobalConfig>,
	) {
		this.rpcs = rpcs;
		this.asyncFetcher = new CRE.AsyncFetcher(sendRequester);
	}

	batchAdd(requests: IRpcRequest[]) {
		requests.forEach(r => {
			const body = {
				id: ++this.reqCounter,
				jsonrpc: "2.0",
				method: r.method,
				params: r.params,
			};

			const request = {
				url: this.rpcs[r.chainSelector][0],
				method: "POST",
				headers,
				body: new TextEncoder().encode(JSON.stringify(body)),
			};

			this.requests.push({ ...request, chainSelector: r.chainSelector });
			this.asyncFetcher.add(request);
		});
	}

	wait(): IRpcResponse {
		let results = this.asyncFetcher.wait();
		let failedRequestsIdxes = this.findFailedRequestsIdxes(results);
		let retryCounter = 0;

		while (failedRequestsIdxes.length && retryCounter < this.maxRetryCount) {
			++retryCounter;

			this.runtime.log(`Retry attempt ${retryCounter}`);

			const failedRequests = failedRequestsIdxes.map(i => this.requests[i]);
			this.batchRotateRpcs(failedRequests.map(r => r.chainSelector));

			this.asyncFetcher.batchAdd(
				failedRequests.map(r => ({
					headers,
					method: "POST",
					url: this.rpcs[r.chainSelector][0],
					body: r.body,
				})),
			);

			const retryResults = this.asyncFetcher.wait();
			this.mergeFailedResults(results, retryResults, failedRequestsIdxes);
		}

		this.requests = [];

		return results.map(res =>
			res.ok ? (CRE.parseCreRawHttpResponse(res.response)?.result ?? null) : null,
		);
	}

	private findFailedRequestsIdxes(results: CRE.IHttpPromiseResult[]) {
		const indexes: number[] = [];

		results.forEach((r, i) => {
			if (this.isFailed(r)) indexes.push(i);
		});

		return indexes;
	}

	private mergeFailedResults(
		results: CRE.IHttpPromiseResult[],
		failedRequestsResults: CRE.IHttpPromiseResult[],
		retryResults: number[],
	) {
		// @dev We go in reverse order so that we can delete elements from the array we are iterating over without any problems.
		for (let i = retryResults.length - 1; i >= 0; i--) {
			const originalIdx = retryResults[i];
			const retryRes = failedRequestsResults[i];

			if (retryRes && !this.isFailed(retryRes)) {
				results[originalIdx] = retryRes;
				retryResults.splice(i, 1);
			} else {
				this.runtime.log(
					`Rpc request failed. Url: ${this.rpcs[this.requests[originalIdx].chainSelector][0]}. ${(retryRes.response as Error)?.message ?? Utility.safeJSONStringify(CRE.parseCreRawHttpResponse(retryRes.response))} `,
				);
			}
		}
	}

	private isFailed(res: CRE.IHttpPromiseResult) {
		if (!res.ok) return true;
		if (res.response?.statusCode !== 200) return true;
		if (!CRE.parseCreRawHttpResponse(res.response as Response)?.result) return true;

		return false;
	}

	private rotateRpcs(chainSelector: ChainSelector) {
		this.rpcs[chainSelector].push(this.rpcs[chainSelector].shift()!);
	}

	private batchRotateRpcs(chainSelectors: ChainSelector[]) {
		const uniqChainSelectors = [...new Set(chainSelectors)];
		uniqChainSelectors.forEach(s => this.rotateRpcs(s));
	}
}
