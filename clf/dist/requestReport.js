(async () => {
	const [_, __, conceroMessage] = bytesArgs;
	const [
		messageId,
		_srcChainSelector,
		dstChainSelector,
		srcBlockNumber,
		receiver,
		tokenAmounts,
		relayers,
		data,
		extraArgs,
	] = new ethers.AbiCoder().decode(
		['bytes32', 'uint64', 'uint64', 'uint64', 'address', 'tuple(address, uint256)[]', 'uint8[]', 'bytes', 'bytes'],
		conceroMessage,
	);
	const chainMap = {
		['1111111111111111111']: {
			urls: ['http://127.0.0.1:8545'],
			confirmations: 3n,
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
	const {confirmations} = chainMap[srcChainSelector];
	while (latestBlockNumber - BigInt(srcBlockNumber) < confirmations) {
		latestBlockNumber = BigInt(await provider.getBlockNumber());
		await sleep(3000);
	}
	const logs = await provider.getLogs({
		address: chainMap[srcChainSelector].conceroRouterAddress,
		topics: [null, messageId],
		fromBlock: latestBlockNumber - 1000n,
		toBlock: latestBlockNumber,
	});
	if (!logs.length) throw new Error('NLF');
	const log = logs[0];
	const abi = [
		'event ConceroMessage(bytes32 indexed, tuple(uint64, address, tuple(address,uint256)[], uint8[], bytes, bytes))',
	];
	const contract = new ethers.Interface(abi);
	const logData = {topics: [log.topics[0], log.topics[1]], data: log.data};
	const decodedLog = contract.parseLog(logData);
	const [logMessageId, logMessageArgs] = decodedLog.args;
	if (logMessageId.toLowerCase() !== messageId.toLowerCase()) throw new Error('WMID');
	if (logMessageArgs[0] !== BigInt(dstChainSelector)) throw new Error('WDC');
	if (logMessageArgs[1].toLowerCase() !== receiver.toLowerCase()) throw new Error('WRV');
	for (let i = 0; i < logMessageArgs[2].length; i++) {
		if (logMessageArgs[2][i].toLowerCase() !== tokenAmounts[i].toLowerCase()) throw new Error('WTA');
	}
	for (let i = 0; i < logMessageArgs[3].length; i++) {
		if (logMessageArgs[3][i] !== relayers[i]) throw new Error('WRL');
	}
	if (logMessageArgs[4].toLowerCase() !== data.toLowerCase()) throw new Error('WD');
	if (logMessageArgs[5].toLowerCase() !== extraArgs.toLowerCase()) throw new Error('WEA');
	const messageHash = ethers.keccak256(
		new ethers.AbiCoder().encode(
			['bytes32', 'tuple(uint64,address,tuple(address,uint256)[],uint8[],bytes,bytes)'],
			[messageId, logMessageArgs],
		),
	);
	return packResult(messageId, messageHash);
})();
