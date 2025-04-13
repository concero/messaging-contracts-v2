import rpc1 from "../common/rpcs/1.json";
import rpc10 from "../common/rpcs/10.json";
import rpc97 from "../common/rpcs/97.json";
import rpc133 from "../common/rpcs/133.json";
import rpc137 from "../common/rpcs/137.json";
import rpc157 from "../common/rpcs/157.json";
import rpc195 from "../common/rpcs/195.json";
import rpc338 from "../common/rpcs/338.json";
import rpc919 from "../common/rpcs/919.json";
import rpc1114 from "../common/rpcs/1114.json";
import rpc1301 from "../common/rpcs/1301.json";
import rpc1328 from "../common/rpcs/1328.json";
import rpc1946 from "../common/rpcs/1946.json";
import rpc2021 from "../common/rpcs/2021.json";
import rpc3636 from "../common/rpcs/3636.json";
import rpc5003 from "../common/rpcs/5003.json";
import rpc6342 from "../common/rpcs/6342.json";
import rpc8453 from "../common/rpcs/8453.json";
import rpc10143 from "../common/rpcs/10143.json";
import rpc10200 from "../common/rpcs/10200.json";
import rpc33111 from "../common/rpcs/33111.json";
import rpc42161 from "../common/rpcs/42161.json";
import rpc43113 from "../common/rpcs/43113.json";
import rpc43114 from "../common/rpcs/43114.json";
import rpc44787 from "../common/rpcs/44787.json";
import rpc48899 from "../common/rpcs/48899.json";
import rpc57054 from "../common/rpcs/57054.json";
import rpc59141 from "../common/rpcs/59141.json";
import rpc80002 from "../common/rpcs/80002.json";
import rpc84532 from "../common/rpcs/84532.json";
import rpc200810 from "../common/rpcs/200810.json";
import rpc421614 from "../common/rpcs/421614.json";
import rpc534351 from "../common/rpcs/534351.json";
import rpc763373 from "../common/rpcs/763373.json";
import rpc11155111 from "../common/rpcs/11155111.json";
import rpc11155420 from "../common/rpcs/11155420.json";
import rpc168587773 from "../common/rpcs/168587773.json";
import { ChainSelector } from "./types";

export interface RpcConfig {
	id: string;
	urls: string[];
	chainSelector?: number;
}

export const rpcConfigs: Record<ChainSelector, RpcConfig> = {
	"1": rpc1 as RpcConfig,
	"10": rpc10 as RpcConfig,
	"11155111": rpc11155111 as RpcConfig,
	"11155420": rpc11155420 as RpcConfig,
	"137": rpc137 as RpcConfig,
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
};
