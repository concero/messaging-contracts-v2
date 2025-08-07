import rpc97 from "@concero/rpcs/output/testnet/97-bnbTestnet.json";
import rpc133 from "@concero/rpcs/output/testnet/133-hashkeyTestnet.json";
import rpc157 from "@concero/rpcs/output/testnet/157-shibariumPuppynet.json";
import rpc195 from "@concero/rpcs/output/testnet/195-xlayerSepolia.json";
import rpc338 from "@concero/rpcs/output/testnet/338-cronosTestnet.json";
import rpc919 from "@concero/rpcs/output/testnet/919-modeTestnet.json";
import rpc1114 from "@concero/rpcs/output/testnet/1114-coreTestnet.json";
import rpc1270 from "@concero/rpcs/output/testnet/1270-irysTestnet.json";
import rpc1301 from "@concero/rpcs/output/testnet/1301-unichainSepolia.json";
import rpc1328 from "@concero/rpcs/output/testnet/1328-seiTestnet.json";
import rpc1946 from "@concero/rpcs/output/testnet/1946-soneiumMinato.json";
import rpc2021 from "@concero/rpcs/output/testnet/2021-roninSaigon.json";
import rpc3636 from "@concero/rpcs/output/testnet/3636-botanixTestnet.json";
import rpc5003 from "@concero/rpcs/output/testnet/5003-mantleSepolia.json";
import rpc6342 from "@concero/rpcs/output/testnet/6342-megaethTestnet.json";
import rpc10143 from "@concero/rpcs/output/testnet/10143-monadTestnet.json";
import rpc10200 from "@concero/rpcs/output/testnet/10200-gnosisChiado.json";
import rpc33111 from "@concero/rpcs/output/testnet/33111-apechainCurtis.json";
import rpc43114 from "@concero/rpcs/output/testnet/43113-avalancheFuji.json";
import rpc43113 from "@concero/rpcs/output/testnet/43113-avalancheFuji.json";
import rpc44787 from "@concero/rpcs/output/testnet/44787-celoAlfajores.json";
import rpc48899 from "@concero/rpcs/output/testnet/48899-zircuitTestnet.json";
import rpc57054 from "@concero/rpcs/output/testnet/57054-sonicBlaze.json";
import rpc59141 from "@concero/rpcs/output/testnet/59141-lineaSepolia.json";
import rpc80002 from "@concero/rpcs/output/testnet/80002-polygonAmoy.json";
import rpc8453 from "@concero/rpcs/output/testnet/84532-baseSepolia.json";
import rpc84532 from "@concero/rpcs/output/testnet/84532-baseSepolia.json";
import rpc200810 from "@concero/rpcs/output/testnet/200810-bitlayerTestnet.json";
import rpc42161 from "@concero/rpcs/output/testnet/421614-arbitrumSepolia.json";
import rpc421614 from "@concero/rpcs/output/testnet/421614-arbitrumSepolia.json";
import rpc534351 from "@concero/rpcs/output/testnet/534351-scrollSepolia.json";
import rpc763373 from "@concero/rpcs/output/testnet/763373-inkSepolia.json";
import rpc11155111 from "@concero/rpcs/output/testnet/11155111-ethereumSepolia.json";
import rpc11155420 from "@concero/rpcs/output/testnet/11155420-optimismSepolia.json";
import rpc168587773 from "@concero/rpcs/output/testnet/168587773-blastSepolia.json";

export interface RpcConfig {
	id: string;
	urls: string[];
	chainSelector?: number;
}

export const rpcConfigs: Record<string, RpcConfig> = {
	"11155111": rpc11155111 as RpcConfig,
	"11155420": rpc11155420 as RpcConfig,
	"42161": rpc42161 as RpcConfig,
	"421614": rpc421614 as RpcConfig,
	"43113": rpc43113 as RpcConfig,
	"43114": rpc43114 as RpcConfig,
	"80002": rpc80002 as RpcConfig,
	"8453": rpc8453 as RpcConfig,
	"84532": rpc84532 as RpcConfig,
	"6342": rpc6342 as RpcConfig,
	"2021": rpc2021 as RpcConfig,
	"57054": rpc57054 as RpcConfig,
	"10143": rpc10143 as RpcConfig,
	"59141": rpc59141 as RpcConfig,
	"97": rpc97 as RpcConfig,
	"1946": rpc1946 as RpcConfig,
	"200810": rpc200810 as RpcConfig,
	"168587773": rpc168587773 as RpcConfig,
	"3636": rpc3636 as RpcConfig,
	"44787": rpc44787 as RpcConfig,
	"1114": rpc1114 as RpcConfig,
	"338": rpc338 as RpcConfig,
	"10200": rpc10200 as RpcConfig,
	"133": rpc133 as RpcConfig,
	"763373": rpc763373 as RpcConfig,
	"5003": rpc5003 as RpcConfig,
	"534351": rpc534351 as RpcConfig,
	"1328": rpc1328 as RpcConfig,
	"157": rpc157 as RpcConfig,
	"1301": rpc1301 as RpcConfig,
	"195": rpc195 as RpcConfig,
	"48899": rpc48899 as RpcConfig,
	"919": rpc919 as RpcConfig,
	"33111": rpc33111 as RpcConfig,
	"1270": rpc1270 as RpcConfig,
};
