export function packResult(
    _messageId: string,
    _messageHash: string,
    chainSelector: bigint,
    blockNumber: bigint,
): Uint8Array {
    const encodeUint64 = (num: bigint) => {
        const hexStr = num.toString(16).padStart(16, "0");
        const arr = new Uint8Array(8);
        for (let i = 0; i < arr.length; i++) {
            arr[i] = parseInt(hexStr.slice(i * 2, i * 2 + 2), 16);
        }
        return arr;
    };
    const resLength = 1 + 32 + 32 + 8 + 8;
    const res = new Uint8Array(resLength);
    res.set(Functions.encodeUint256(BigInt(_messageId)), 1);
    res.set(Functions.encodeUint256(BigInt(_messageHash)), 33);
    res.set(encodeUint64(chainSelector), 65);
    res.set(encodeUint64(blockNumber), 73);
    return res;
}
