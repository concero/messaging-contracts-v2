import rpc1 from "../common/rpcs/1.json";
import rpc10 from "../common/rpcs/10.json";
import rpc137 from "../common/rpcs/137.json";
import rpc6342 from "../common/rpcs/6342.json";
import rpc8453 from "../common/rpcs/8453.json";
import rpc42161 from "../common/rpcs/42161.json";
import rpc43113 from "../common/rpcs/43113.json";
import rpc43114 from "../common/rpcs/43114.json";
import rpc80002 from "../common/rpcs/80002.json";
import rpc84532 from "../common/rpcs/84532.json";
import rpc421614 from "../common/rpcs/421614.json";
import rpc11155111 from "../common/rpcs/11155111.json";
import rpc11155420 from "../common/rpcs/11155420.json";
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
};
