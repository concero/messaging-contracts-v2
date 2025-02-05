(async () => {
	const [_, __, messageId, conceroMessage] = bytesArgs;
	const decodedConceroMessage = new ethers.AbiCoder().decode(
		['tuple(uint64, uint64, address, address, tuple(address, uint256)[], uint8[], bytes, bytes)'],
		conceroMessage,
	);
	const [_srcChainSelector, dstChainSelector, receiver, sender, tokenAmounts, relayers, data, extraArgs] =
		decodedConceroMessage[0];

	const chainMap = {
		// testnets

		// ['${CL_CCIP_CHAIN_SELECTOR_FUJI}']: {
		// 	urls: ['https://rpc.ankr.com/avalanche_fuji'],
		// 	confirmations: 3n,
		// 	chainId: '0xa869',
		// 	conceroRouterAddress: '${CONCERO_ROUTER_PROXY_AVALANCHE_FUJI}',
		// },
		// ['${CL_CCIP_CHAIN_SELECTOR_SEPOLIA}']: {
		// 	urls: ['https://ethereum-sepolia-rpc.publicnode.com', 'https://ethereum-sepolia.blockpi.network/v1/rpc/public'],
		// 	confirmations: 3n,
		// 	chainId: '0xaa36a7',
		// 	conceroRouterAddress: '${CONCERO_ROUTER_PROXY_SEPOLIA}',
		// },
		['${CL_CCIP_CHAIN_SELECTOR_ARBITRUM_SEPOLIA}']: {
			urls: ['https://rpc.ankr.com/arbitrum_sepolia', 'https://arbitrum-sepolia-rpc.publicnode.com'],
			confirmations: 3n,
			chainId: '0x66eee',
			conceroRouterAddress: '${CONCERO_ROUTER_PROXY_ARBITRUM_SEPOLIA}',
		},
		['${CL_CCIP_CHAIN_SELECTOR_BASE_SEPOLIA}']: {
			urls: ['https://rpc.ankr.com/base_sepolia', 'https://base-sepolia-rpc.publicnode.com'],
			confirmations: 3n,
			chainId: '0x14a34',
			conceroRouterAddress: '${CONCERO_ROUTER_PROXY_BASE_SEPOLIA}',
		},
		// ['${CL_CCIP_CHAIN_SELECTOR_OPTIMISM_SEPOLIA}']: {
		// 	urls: ['https://rpc.ankr.com/optimism_sepolia', 'https://optimism-sepolia-rpc.publicnode.com'],
		// 	confirmations: 3n,
		// 	chainId: '0xaa37dc',
		// 	conceroRouterAddress: '${CONCERO_ROUTER_PROXY_OPTIMISM_SEPOLIA}',
		// },
		// ['${CL_CCIP_CHAIN_SELECTOR_POLYGON_AMOY}']: {
		// 	urls: ['https://polygon-amoy-bor-rpc.publicnode.com', 'https://rpc.ankr.com/polygon_amoy'],
		// 	confirmations: 3n,
		// 	chainId: '0x13882',
		// 	conceroRouterAddress: '${CONCERO_ROUTER_PROXY_POLYGON_AMOY}',
		// },
		//
		// // mainnets
		//
		// ['${CL_CCIP_CHAIN_SELECTOR_POLYGON}']: {
		// 	urls: ['https://polygon-bor-rpc.publicnode.com', 'https://rpc.ankr.com/polygon'],
		// 	confirmations: 3n,
		// 	chainId: '0x89',
		// 	conceroRouterAddress: '${CONCERO_ROUTER_PROXY_POLYGON}',
		// },
		// ['${CL_CCIP_CHAIN_SELECTOR_ARBITRUM}']: {
		// 	urls: ['https://arbitrum-rpc.publicnode.com', 'https://rpc.ankr.com/arbitrum'],
		// 	confirmations: 3n,
		// 	chainId: '0xa4b1',
		// 	conceroRouterAddress: '${CONCERO_ROUTER_PROXY_ARBITRUM}',
		// },
		// ['${CL_CCIP_CHAIN_SELECTOR_BASE}']: {
		// 	urls: ['https://base-rpc.publicnode.com', 'https://rpc.ankr.com/base'],
		// 	confirmations: 3n,
		// 	chainId: '0x2105',
		// 	conceroRouterAddress: '${CONCERO_ROUTER_PROXY_BASE}',
		// },
		// ['${CL_CCIP_CHAIN_SELECTOR_AVALANCHE}']: {
		// 	urls: ['https://avalanche-c-chain-rpc.publicnode.com', 'https://rpc.ankr.com/avalanche'],
		// 	confirmations: 3n,
		// 	chainId: '0xa86a',
		// 	conceroRouterAddress: '${CONCERO_ROUTER_PROXY_AVALANCHE}',
		// },

		//tests

		['${CL_CCIP_CHAIN_SELECTOR_LOCALHOST}']: {
			urls: ['${LOCALHOST_RPC_URL}'],
			confirmations: 0n,
			chainId: '0x7A69',
			conceroRouterAddress: '0x23494105b6B8cEaA0eB9c051b7e4484724641821',
		},
	};
	const srcChainSelector = _srcChainSelector.toString();
	const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
	class FunctionsJsonRpcProvider extends ethers.JsonRpcProvider {
		constructor(url) {
			super(url);
			this.url = url;
		}
		async _send(payload) {
			if (payload.method === 'eth_chainId') {
				return [{jsonrpc: '2.0', id: payload.id, result: chainMap[srcChainSelector].chainId}];
			}
			const resp = await fetch(this.url, {
				method: 'POST',
				headers: {'Content-Type': 'application/json'},
				body: JSON.stringify(payload),
			});
			const result = await resp.json();
			if (payload.length === undefined) {
				return [result];
			}
			return result;
		}
	}
	const packResult = (_messageId, _messageHash, chainSelector, blockNumber) => {
		const encodeUint64 = num => {
			const hexStr = num.toString(16).padStart(16, '0');
			const arr = new Uint8Array(8);
			for (let i = 0; i < arr.length; i++) {
				arr[i] = parseInt(hexStr.slice(i * 2, i * 2 + 2), 16);
			}
			return arr;
		};
		const resLength = 1 + 32 + 32 + 8 + 8;
		const res = new Uint8Array(resLength);
		res.set(Functions.encodeUint256(BigInt(_messageId)), 1);
		res.set(Functions.encodeUint256(BigInt(_messageHash)), 33);
		res.set(encodeUint64(chainSelector), 65);
		res.set(encodeUint64(blockNumber), 73);
		return res;
	};

	const provider = new FunctionsJsonRpcProvider(
		chainMap[srcChainSelector].urls[Math.floor(Math.random() * chainMap[srcChainSelector].urls.length)],
	);

	const getLogByMessageId = async (_messageId, _latestBlockNumber) => {
		const logs = await provider.getLogs({
			address: chainMap[srcChainSelector].conceroRouterAddress,
			topics: [null, messageId],
			fromBlock: _latestBlockNumber - 1000n,
			toBlock: _latestBlockNumber,
		});

		if (!logs.length) throw new Error('NLF');

		return logs[0];
	};

	let latestBlockNumber = BigInt(await provider.getBlockNumber());
	const {confirmations} = chainMap[srcChainSelector];
	const srcBlockNumber = await getLogByMessageId(messageId, latestBlockNumber).then(log => BigInt(log.blockNumber));

	while (latestBlockNumber - BigInt(srcBlockNumber) < confirmations) {
		latestBlockNumber = BigInt(await provider.getBlockNumber());
		await sleep(3000);
	}

	const log = await getLogByMessageId(messageId, latestBlockNumber);
	const abi = [
		'event ConceroMessageSent(bytes32 indexed, tuple(uint64, uint64, address, address, tuple(address,uint256)[], uint8[], bytes, bytes))',
	];
	const contract = new ethers.Interface(abi);
	const logData = {topics: [log.topics[0], log.topics[1]], data: log.data};
	const decodedLog = contract.parseLog(logData);
	const [logMessageId, logMessageArgs] = decodedLog.args;

	if (logMessageId.toLowerCase() !== messageId.toLowerCase()) throw new Error('WMID');
	if (logMessageArgs[0] !== BigInt(srcChainSelector)) throw new Error('WSC');
	if (logMessageArgs[1] !== BigInt(dstChainSelector)) throw new Error('WDC');
	if (logMessageArgs[2].toLowerCase() !== receiver.toLowerCase()) throw new Error('WRV');
	if (logMessageArgs[3].toLowerCase() !== sender.toLowerCase()) throw new Error('WRS');
	for (let i = 0; i < logMessageArgs[4].length; i++) {
		if (logMessageArgs[4][i][0].toLowerCase() !== tokenAmounts[i][0].toLowerCase()) throw new Error('WTT');
		if (logMessageArgs[4][i][1] !== tokenAmounts[i][1]) throw new Error('WTA');
	}
	for (let i = 0; i < logMessageArgs[5].length; i++) {
		if (logMessageArgs[5][i] !== relayers[i]) throw new Error('WRL');
	}
	if (logMessageArgs[6].toLowerCase() !== data.toLowerCase()) throw new Error('WD');
	if (logMessageArgs[7].toLowerCase() !== extraArgs.toLowerCase()) throw new Error('WEA');

	const messageBytes = new ethers.AbiCoder().encode(
		['bytes32', 'tuple(uint64,uint64,address,address,tuple(address,uint256)[],uint8[],bytes,bytes)'],
		[messageId, [srcChainSelector, dstChainSelector, receiver, sender, tokenAmounts, relayers, data, extraArgs]],
	);
	const messageHash = ethers.keccak256(messageBytes);

	return packResult(messageId, messageHash, BigInt(srcChainSelector), BigInt(srcBlockNumber));
})();
