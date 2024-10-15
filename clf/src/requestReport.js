(() => {
	const chainMap = {
		// testnets

		['${CL_CCIP_CHAIN_SELECTOR_FUJI}']: {
			urls: ['https://rpc.ankr.com/avalanche_fuji'],
			confirmations: 3n,
			chainId: '0xa869',
		},
		['${CL_CCIP_CHAIN_SELECTOR_SEPOLIA}']: {
			urls: ['https://ethereum-sepolia-rpc.publicnode.com', 'https://ethereum-sepolia.blockpi.network/v1/rpc/public'],
			confirmations: 3n,
			chainId: '0xaa36a7',
		},
		['${CL_CCIP_CHAIN_SELECTOR_ARBITRUM_SEPOLIA}']: {
			urls: ['https://rpc.ankr.com/arbitrum_sepolia', 'https://arbitrum-sepolia-rpc.publicnode.com'],
			confirmations: 3n,
			chainId: '0x66eee',
		},
		['${CL_CCIP_CHAIN_SELECTOR_BASE_SEPOLIA}']: {
			urls: ['https://rpc.ankr.com/base_sepolia', 'https://base-sepolia-rpc.publicnode.com'],
			confirmations: 3n,
			chainId: '0x14a34',
		},
		['${CL_CCIP_CHAIN_SELECTOR_OPTIMISM_SEPOLIA}']: {
			urls: ['https://rpc.ankr.com/optimism_sepolia', 'https://optimism-sepolia-rpc.publicnode.com'],
			confirmations: 3n,
			chainId: '0xaa37dc',
		},
		['${CL_CCIP_CHAIN_SELECTOR_POLYGON_AMOY}']: {
			urls: ['https://polygon-amoy-bor-rpc.publicnode.com', 'https://rpc.ankr.com/polygon_amoy'],
			confirmations: 3n,
			chainId: '0x13882',
		},

		// mainnets

		['${CL_CCIP_CHAIN_SELECTOR_POLYGON}']: {
			urls: ['https://polygon-bor-rpc.publicnode.com', 'https://rpc.ankr.com/polygon'],
			confirmations: 3n,
			chainId: '0x89',
		},
		['${CL_CCIP_CHAIN_SELECTOR_ARBITRUM}']: {
			urls: ['https://arbitrum-rpc.publicnode.com', 'https://rpc.ankr.com/arbitrum'],
			confirmations: 3n,
			chainId: '0xa4b1',
		},
		['${CL_CCIP_CHAIN_SELECTOR_BASE}']: {
			urls: ['https://base-rpc.publicnode.com', 'https://rpc.ankr.com/base'],
			confirmations: 3n,
			chainId: '0x2105',
		},
		['${CL_CCIP_CHAIN_SELECTOR_AVALANCHE}']: {
			urls: ['https://avalanche-c-chain-rpc.publicnode.com', 'https://rpc.ankr.com/avalanche'],
			confirmations: 3n,
			chainId: '0xa86a',
		},
	};
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

	// const ethersId = ethers.id('CCIPSent(bytes32,address,address,uint8,uint256,uint64)');
	// const logs = await provider.getLogs({
	//     address: srcContractAddress,
	//     topics: [ethersId, messageId],
	//     fromBlock: latestBlockNumber - 1000n,
	//     toBlock: latestBlockNumber,
	// });
})();
