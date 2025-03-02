import type { Chain } from "viem";
import { base, mainnet } from "viem/chains";

const viemChains: Record<number, Chain> = {
    1: mainnet,
    8453: base,
};
export { viemChains };
