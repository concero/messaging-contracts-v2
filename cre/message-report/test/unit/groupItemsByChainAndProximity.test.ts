import { describe, expect, spyOn, beforeEach, afterEach } from "bun:test";
import { test } from "@chainlink/cre-sdk/test";
import type { Hash } from "viem";

import { groupItemsByChainAndProximity } from "../../pipeline/fetchLogsByMessageIds";
import { ChainsManager, type Chain, type ChainSelector } from "../../systems";
import type { DecodedArgs } from "../../helpers";
import { createTestRuntime } from "../utils";

type BatchItem = DecodedArgs["batch"][number];

let spy: ReturnType<typeof spyOn>;

function batchItem(overrides: Partial<BatchItem> = {}): BatchItem {
	return {
		messageId: "0xaa01" as Hash,
		srcChainSelector: 1,
		blockNumber: "100",
		...overrides,
	};
}

function chainConfig(overrides: Partial<Chain> = {}): Chain {
	return {
		id: "1",
		chainSelector: 1,
		name: "testChain",
		isTestnet: true,
		minBlockConfirmations: 3,
		rpcUrls: ["https://rpc.example.com"],
		blockExplorers: [],
		nativeCurrency: { name: "ETH", symbol: "ETH", decimals: 18 },
		deployments: {
			router: "0x85d41c3aEB692e505bEE9820F938b7BD5642e95A",
		},
		...overrides,
	};
}

beforeEach(() => {
	spy = spyOn(ChainsManager, "getOptionsBySelector");
});

afterEach(() => {
	spy.mockRestore();
});

// --- 1. Chain config filtering ---

describe("groupItemsByChainAndProximity", () => {
	describe("chain config filtering", () => {
		test("should skip chain if no router deployment", async () => {
			spy.mockReturnValue(chainConfig({ deployments: {} }));
			const runtime = createTestRuntime();

			const result = groupItemsByChainAndProximity(runtime, [batchItem()]);

			expect(result).toEqual([]);
			const logs = runtime.getLogs();
			expect(logs.some(l => l.includes("Router deployment not found for chain 1"))).toBe(
				true,
			);
		});

		test("should skip chain if empty rpcUrls", async () => {
			spy.mockReturnValue(chainConfig({ rpcUrls: [] }));
			const runtime = createTestRuntime();

			const result = groupItemsByChainAndProximity(runtime, [batchItem()]);

			expect(result).toEqual([]);
			const logs = runtime.getLogs();
			expect(logs.some(l => l.includes("Rpcs for chain 1 not found"))).toBe(true);
		});
	});

	// --- 2. Single chain, single block ---

	describe("single chain, single block", () => {
		test("single item should produces one group", async () => {
			spy.mockReturnValue(chainConfig());
			const runtime = createTestRuntime();

			const result = groupItemsByChainAndProximity(runtime, [
				batchItem({ blockNumber: "200" }),
			]);

			expect(result).toHaveLength(1);
			expect(result[0].minBlock).toBe(200n);
			expect(result[0].maxBlock).toBe(200n);
			expect(result[0].messageIds).toHaveLength(1);
		});

		test("two items in same block should merge into one group", async () => {
			spy.mockReturnValue(chainConfig());
			const runtime = createTestRuntime();

			const result = groupItemsByChainAndProximity(runtime, [
				batchItem({ blockNumber: "200", messageId: "0xaa01" as Hash }),
				batchItem({ blockNumber: "200", messageId: "0xaa02" as Hash }),
			]);

			expect(result).toHaveLength(1);
			expect(result[0].messageIds).toHaveLength(2);
		});
	});

	// --- 3. Proximity boundary conditions ---
	describe("proximity boundaries", () => {
		test("default depth for chain should splits logs into 2 groups", async () => {
			spy.mockReturnValue(chainConfig());
			const runtime = createTestRuntime();

			const result = groupItemsByChainAndProximity(runtime, [
				batchItem({ blockNumber: "100", messageId: "0xaa01" as Hash }),
				batchItem({ blockNumber: "101", messageId: "0xaa02" as Hash }),
			]);

			expect(result).toHaveLength(2);
		});

		test("custom depth should merge logs to 1 group when all within range", async () => {
			// blockDepth=100, blocks 100,150,190: 190-100+10=100 <= 100
			spy.mockReturnValue(chainConfig({ getLogsBlockDepth: 100 }));
			const runtime = createTestRuntime();

			const result = groupItemsByChainAndProximity(runtime, [
				batchItem({ blockNumber: "100", messageId: "0xaa01" as Hash }),
				batchItem({ blockNumber: "150", messageId: "0xaa02" as Hash }),
				batchItem({ blockNumber: "190", messageId: "0xaa03" as Hash }),
			]);

			expect(result).toHaveLength(1);
			expect(result[0].minBlock).toBe(100n);
			expect(result[0].maxBlock).toBe(190n);
			expect(result[0].messageIds).toHaveLength(3);
		});

		test("should create 2 groups when max block number exceeds depth", async () => {
			// blockDepth=100, blocks 100,191: 191-100+10=101 > 100
			spy.mockReturnValue(chainConfig({ getLogsBlockDepth: 100 }));
			const runtime = createTestRuntime();

			const result = groupItemsByChainAndProximity(runtime, [
				batchItem({ blockNumber: "100", messageId: "0xaa01" as Hash }),
				batchItem({ blockNumber: "191", messageId: "0xaa02" as Hash }),
			]);

			expect(result).toHaveLength(2);
		});

		test("should create separate groups for far apart blocks", async () => {
			// blockDepth=100, blocks 100,500,1000 -> 3 groups
			spy.mockReturnValue(chainConfig({ getLogsBlockDepth: 100 }));
			const runtime = createTestRuntime();

			const result = groupItemsByChainAndProximity(runtime, [
				batchItem({ blockNumber: "100", messageId: "0xaa01" as Hash }),
				batchItem({ blockNumber: "500", messageId: "0xaa02" as Hash }),
				batchItem({ blockNumber: "1000", messageId: "0xaa03" as Hash }),
			]);

			expect(result).toHaveLength(3);
		});

		test("should create 2 groups depend on depth", async () => {
			// blockDepth=100, blocks 100,150,180,500
			// 180-100+10=90 <= 100 -> group1: [100,150,180]
			// 500-100+10=410 > 100 -> group2: [500]
			spy.mockReturnValue(chainConfig({ getLogsBlockDepth: 100 }));
			const runtime = createTestRuntime();

			const result = groupItemsByChainAndProximity(runtime, [
				batchItem({ blockNumber: "100", messageId: "0xaa01" as Hash }),
				batchItem({ blockNumber: "150", messageId: "0xaa02" as Hash }),
				batchItem({ blockNumber: "180", messageId: "0xaa03" as Hash }),
				batchItem({ blockNumber: "500", messageId: "0xaa04" as Hash }),
			]);

			expect(result).toHaveLength(2);
			expect(result[0].messageIds).toHaveLength(3);
			expect(result[0].minBlock).toBe(100n);
			expect(result[0].maxBlock).toBe(180n);
			expect(result[1].messageIds).toHaveLength(1);
			expect(result[1].minBlock).toBe(500n);
		});
	});

	// --- 4. Sorting ---

	describe("sorting", () => {
		test("unsorted input is sorted before grouping", async () => {
			spy.mockReturnValue(chainConfig({ getLogsBlockDepth: 100 }));
			const runtime = createTestRuntime();

			const result = groupItemsByChainAndProximity(runtime, [
				batchItem({ blockNumber: "500", messageId: "0xaa01" as Hash }),
				batchItem({ blockNumber: "100", messageId: "0xaa02" as Hash }),
				batchItem({ blockNumber: "300", messageId: "0xaa03" as Hash }),
			]);

			expect(result).toHaveLength(3);
			expect(result[0].minBlock).toBe(100n);
			expect(result[1].minBlock).toBe(300n);
			expect(result[2].minBlock).toBe(500n);
		});
	});

	// --- 5. Multiple chains ---

	describe("multiple chains", () => {
		test("different chains should create different groups", async () => {
			const chainA = chainConfig({
				chainSelector: 1,
				deployments: { router: "0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" },
			});
			const chainB = chainConfig({
				chainSelector: 2,
				deployments: { router: "0xBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB" },
			});

			spy.mockImplementation((selector: ChainSelector) => {
				if (selector === 1) return chainA;
				return chainB;
			});

			const runtime = createTestRuntime();
			const result = groupItemsByChainAndProximity(runtime, [
				batchItem({ srcChainSelector: 1, messageId: "0xaa01" as Hash }),
				batchItem({ srcChainSelector: 2, messageId: "0xaa02" as Hash }),
			]);

			expect(result).toHaveLength(2);
			const selectors = result.map(g => g.chainSelector);
			expect(selectors).toContain(1);
			expect(selectors).toContain(2);

			const groupA = result.find(g => g.chainSelector === 1)!;
			const groupB = result.find(g => g.chainSelector === 2)!;
			expect(groupA.routerAddress).toBe("0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			expect(groupB.routerAddress).toBe("0xBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB");
		});

		test("per-chain blockDepth affects grouping", async () => {
			// Chain A: depth=100, blocks 100,190 -> 190-100+10=100 <= 100 -> 1 group
			// Chain B: depth=50, blocks 100,190 -> 190-100+10=100 > 50 -> 2 groups
			const chainA = chainConfig({
				chainSelector: 1,
				getLogsBlockDepth: 100,
			});
			const chainB = chainConfig({
				chainSelector: 2,
				getLogsBlockDepth: 50,
			});

			spy.mockImplementation((selector: ChainSelector) => {
				if (selector === 1) return chainA;
				return chainB;
			});

			const runtime = createTestRuntime();
			const result = groupItemsByChainAndProximity(runtime, [
				batchItem({ srcChainSelector: 1, blockNumber: "100", messageId: "0xaa01" as Hash }),
				batchItem({ srcChainSelector: 1, blockNumber: "190", messageId: "0xaa02" as Hash }),
				batchItem({ srcChainSelector: 2, blockNumber: "100", messageId: "0xaa03" as Hash }),
				batchItem({ srcChainSelector: 2, blockNumber: "190", messageId: "0xaa04" as Hash }),
			]);

			const groupsA = result.filter(g => g.chainSelector === 1);
			const groupsB = result.filter(g => g.chainSelector === 2);

			expect(groupsA).toHaveLength(1);
			expect(groupsB).toHaveLength(2);
		});
	});
});
