import type { Chain } from "viem";
import { mainnet } from "viem/chains";

const viemChains: Record<number, Chain> = {
    "1": mainnet,
};
export { viemChains };
