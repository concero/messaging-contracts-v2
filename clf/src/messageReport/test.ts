import { main } from "./index";

async function test() {
    const VERSION = 0n;
    const SRC_CHAIN_SELECTOR = 8n;
    const DST_CHAIN_SELECTOR = 32n;
    const MIN_SRC_CONF = 56n;
    const MIN_DST_CONF = 72n;
    const RELAYER_CONFIG = 88n;
    const IS_CALLBACKABLE = 96n;

    const messageConfig =
        (1n << VERSION) | // version = 1
        (100n << SRC_CHAIN_SELECTOR) | // srcChainSelector = 100
        (1n << DST_CHAIN_SELECTOR) | // dstChainSelector = 1
        (2n << MIN_SRC_CONF) | // minSrcConfirmations = 2
        (1n << MIN_DST_CONF) | // minDstConfirmations = 1
        (3n << RELAYER_CONFIG) | // relayerConfig = 3
        (1n << IS_CALLBACKABLE); // isCallbackable = true

    const inputArgs = [
        "0x1234", // Dummy hash
        "0x" + messageConfig.toString(16).padStart(64, "0"),
        "0x0000000000000000000000000000000000000000000000000000000000000456", // messageId
        "0x0000000000000000000000000000000000000000000000000000000000000789", // messageHashSum
        "0x" + Buffer.from("test").toString("hex"), // srcChainData
        "0x1234567890123456789012345678901234567890", // operatorAddress (valid ethereum address)
    ];

    await main(inputArgs);
}

test();
