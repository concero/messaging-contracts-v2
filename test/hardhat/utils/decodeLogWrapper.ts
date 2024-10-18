import { decodeEventLog } from "viem";

export const decodeLogWrapper = (abi: any, log: any) => {
    try {
        return decodeEventLog({
            abi,
            topics: log.topics,
            data: log.data,
            strict: false,
        });
    } catch (e) {
        return;
    }
};
