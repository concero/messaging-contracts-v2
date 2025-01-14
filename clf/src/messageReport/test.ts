import { main } from "./index";
import { BIT_MASKS as masks, INTERNAL_MESSAGE_REPORT_BIT_OFFSETS as offsets } from "./constants/bitOffsets";

async function test() {
    // Create a valid `messageConfig`
    const messageConfig =
        (1n << offsets.VERSION) | // version = 1
        (100n << offsets.SRC_CHAIN_SELECTOR) | // srcChainSelector = 100
        (1n << offsets.DST_CHAIN_SELECTOR) | // dstChainSelector = 1
        (2n << offsets.MIN_SRC_CONF) | // minSrcConfirmations = 2
        (1n << offsets.MIN_DST_CONF) | // minDstConfirmations = 1
        (3n << offsets.RELAYER_CONFIG) | // relayerConfig = 3
        (1n << offsets.IS_CALLBACKABLE); // isCallbackable = true

    // Convert `messageConfig` to hex string for the test
    const inputArgs = ["", "", `0x${messageConfig.toString(16)}`, "0x456", "0x789", "10"];

    try {
        const result = await main(inputArgs);
        console.log("Test Passed:", result);
    } catch (error) {
        console.error("Test Failed:", error.message);
    }
}

test();
