import type { Address } from "viem";

const CONCERO_VERIFIER_CONTRACT_ADDRESS = CONCERO_VERIFIER;
const conceroRouters: Record<number, Address> = {
    "1": CONCERO_ROUTER,
};
export { conceroRouters, CONCERO_VERIFIER_CONTRACT_ADDRESS };
