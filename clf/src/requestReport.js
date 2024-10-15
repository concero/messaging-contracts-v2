(async () => {
    const [_, __, conceroMessage] = bytesArgs;
    const [
        messageId,
        srcChainSelector,
        dstChainSelector,
        srcBlockNumber,
        receiver,
        tokenAmounts,
        relayers,
        data,
        extraArgs,
    ] = conceroMessage;
    const chainMap = {
        // testnets

        ["${CL_CCIP_CHAIN_SELECTOR_FUJI}"]: {
            urls: ["https://rpc.ankr.com/avalanche_fuji"],
            confirmations: 3n,
            chainId: "0xa869",
            conceroRouterAddress: "${CONCERO_ROUTER_PROXY_AVALANCHE_FUJI}",
        },
        ["${CL_CCIP_CHAIN_SELECTOR_SEPOLIA}"]: {
            urls: [
                "https://ethereum-sepolia-rpc.publicnode.com",
                "https://ethereum-sepolia.blockpi.network/v1/rpc/public",
            ],
            confirmations: 3n,
            chainId: "0xaa36a7",
            conceroRouterAddress: "${CONCERO_ROUTER_PROXY_SEPOLIA}",
        },
        ["${CL_CCIP_CHAIN_SELECTOR_ARBITRUM_SEPOLIA}"]: {
            urls: ["https://rpc.ankr.com/arbitrum_sepolia", "https://arbitrum-sepolia-rpc.publicnode.com"],
            confirmations: 3n,
            chainId: "0x66eee",
            conceroRouterAddress: "${CONCERO_ROUTER_PROXY_ARBITRUM_SEPOLIA}",
        },
        ["${CL_CCIP_CHAIN_SELECTOR_BASE_SEPOLIA}"]: {
            urls: ["https://rpc.ankr.com/base_sepolia", "https://base-sepolia-rpc.publicnode.com"],
            confirmations: 3n,
            chainId: "0x14a34",
            conceroRouterAddress: "${CONCERO_ROUTER_PROXY_BASE_SEPOLIA}",
        },
        ["${CL_CCIP_CHAIN_SELECTOR_OPTIMISM_SEPOLIA}"]: {
            urls: ["https://rpc.ankr.com/optimism_sepolia", "https://optimism-sepolia-rpc.publicnode.com"],
            confirmations: 3n,
            chainId: "0xaa37dc",
            conceroRouterAddress: "${CONCERO_ROUTER_PROXY_OPTIMISM_SEPOLIA}",
        },
        ["${CL_CCIP_CHAIN_SELECTOR_POLYGON_AMOY}"]: {
            urls: ["https://polygon-amoy-bor-rpc.publicnode.com", "https://rpc.ankr.com/polygon_amoy"],
            confirmations: 3n,
            chainId: "0x13882",
            conceroRouterAddress: "${CONCERO_ROUTER_PROXY_POLYGON_AMOY}",
        },

        // mainnets

        ["${CL_CCIP_CHAIN_SELECTOR_POLYGON}"]: {
            urls: ["https://polygon-bor-rpc.publicnode.com", "https://rpc.ankr.com/polygon"],
            confirmations: 3n,
            chainId: "0x89",
            conceroRouterAddress: "${CONCERO_ROUTER_PROXY_POLYGON}",
        },
        ["${CL_CCIP_CHAIN_SELECTOR_ARBITRUM}"]: {
            urls: ["https://arbitrum-rpc.publicnode.com", "https://rpc.ankr.com/arbitrum"],
            confirmations: 3n,
            chainId: "0xa4b1",
            conceroRouterAddress: "${CONCERO_ROUTER_PROXY_ARBITRUM}",
        },
        ["${CL_CCIP_CHAIN_SELECTOR_BASE}"]: {
            urls: ["https://base-rpc.publicnode.com", "https://rpc.ankr.com/base"],
            confirmations: 3n,
            chainId: "0x2105",
            conceroRouterAddress: "${CONCERO_ROUTER_PROXY_BASE}",
        },
        ["${CL_CCIP_CHAIN_SELECTOR_AVALANCHE}"]: {
            urls: ["https://avalanche-c-chain-rpc.publicnode.com", "https://rpc.ankr.com/avalanche"],
            confirmations: 3n,
            chainId: "0xa86a",
            conceroRouterAddress: "${CONCERO_ROUTER_PROXY_AVALANCHE}",
        },
    };
    const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
    class FunctionsJsonRpcProvider extends ethers.JsonRpcProvider {
        constructor(url) {
            super(url);
            this.url = url;
        }
        async _send(payload) {
            if (payload.method === "eth_chainId") {
                return [{ jsonrpc: "2.0", id: payload.id, result: chainMap[srcChainSelector].chainId }];
            }
            const resp = await fetch(this.url, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(payload),
            });
            const result = await resp.json();
            if (payload.length === undefined) {
                return [result];
            }
            return result;
        }
    }
    const packResult = (_messageId, _messageHash) => {
        const resLength = 1 + 32 + 32;
        const res = new Uint8Array(resLength);
        const encodedMessageId = Functions.encodeUint256(BigInt(_messageId));
        const encodedMessageHash = Functions.encodeUint256(BigInt(_messageHash));
        res.set(encodedMessageId, 1);
        res.set(encodedMessageHash, 33);
        return res;
    };

    const provider = new FunctionsJsonRpcProvider(
        chainMap[srcChainSelector].urls[Math.floor(Math.random() * chainMap[srcChainSelector].urls.length)],
    );
    let latestBlockNumber = BigInt(await provider.getBlockNumber());
    const { confirmations } = chainMap[srcChainSelector];

    while (latestBlockNumber - BigInt(srcBlockNumber) < confirmations) {
        latestBlockNumber = BigInt(await provider.getBlockNumber());
        await sleep(3000);
    }

    const messageTuple = "tuple(uint64,receiver,tuple(address,uint256)[],uint8[],bytes,bytes)";
    const ethersId = ethers.id("ConceroMessage(bytes32," + messageTuple + ")");
    const logs = await provider.getLogs({
        address: chainMap[srcChainSelector].conceroRouterAddress,
        topics: [ethersId],
        fromBlock: latestBlockNumber - 1000n,
        toBlock: latestBlockNumber,
    });

    if (!logs.length) throw new Error("NLF");

    const log = logs[0];
    const abi = [
        "event ConceroMessage(bytes32, tuple(uint64, address, tuple(address,uint256)[], uint8[], bytes, bytes))",
    ];
    const contract = new ethers.Interface(abi);
    const logData = { topics: [ethersId, log.topics[1]], data: log.data };
    const decodedLog = contract.parseLog(logData);

    if (decodedLog.args[0].toLowerCase() !== messageId.toLowerCase()) throw new Error("WMID");
    if (decodedLog.args[1].toLowerCase() !== dstChainSelector.toLowerCase()) throw new Error("WDC");
    if (decodedLog.args[2].toLowerCase() !== receiver.toLowerCase()) throw new Error("WRV");
    for (let i = 0; i < decodedLog.args[3].length; i++) {
        if (decodedLog.args[3][i].toLowerCase() !== tokenAmounts[i].toLowerCase()) throw new Error("WTA");
    }
    for (let i = 0; i < decodedLog.args[4].length; i++) {
        if (decodedLog.args[4][i] !== relayers[i]) throw new Error("WRL");
    }
    if (decodedLog.args[5].toLowerCase() !== data.toLowerCase()) throw new Error("WD");
    if (decodedLog.args[6].toLowerCase() !== extraArgs.toLowerCase()) throw new Error("WEA");

    const messageHash = ethers.utils.keccak256(
        ethers.utils.defaultAbiCoder.encode(["bytes32", messageTuple], [messageId, ...decodedLog.args]),
    );

    return packResult(messageId, messageHash);
})();
