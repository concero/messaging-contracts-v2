type DeployConfigTestnet = {
	[key: string]: {
		priceFeed?: {
			gasLimit: number;
		};
		proxyAdmin?: {
			gasLimit: number;
		};
		proxy?: {
			gasLimit: number;
		};
	};
};

export const DEPLOY_CONFIG_TESTNET: DeployConfigTestnet = {
	inkSepolia: {
		priceFeed: {
			gasLimit: 1000000,
		},
	},
	b2Testnet: {
		priceFeed: {
			gasLimit: 1000000,
		},
	},
	seismicDevnet: {
		priceFeed: {
			gasLimit: 500000,
		},
	},
	viction: {
		priceFeed: {
			gasLimit: 3_000_000,
		},
		proxy: {
			gasLimit: 3_000_000,
		},
	},
};
