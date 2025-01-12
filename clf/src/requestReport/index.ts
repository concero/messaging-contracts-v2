import { keccak256, encodeAbiParameters } from "viem";
import { packResult } from "./packResult";
import { ClientMessageRequest, conceroRouters, ErrorType } from "./constants";
import { getPublicClient } from "./viemClient";
import { decodeInternalMessageConfig, validateInternalMessageConfig } from "./messageConfig";
import { decodeConceroMessageLog, fetchConceroMessage } from "./utils";

export async function main(bytesArgs: string[]) {
    if (bytesArgs.length < 6) throw new Error(ErrorType.INVALID_INPUT);
    const [_, messageConfig, messageId, messageHashSum, srcBlockNumber, relayerAddress] = bytesArgs;

    const decodedInternalMessageConfig = decodeInternalMessageConfig(BigInt(messageConfig));
    validateInternalMessageConfig(decodedInternalMessageConfig);

    const {
        version,
        srcChainSelector,
        dstChainSelector,
        minSrcConfirmations,
        minDstConfirmations,
        relayerConfig,
        isCallbackable,
    } = decodedInternalMessageConfig;

    const client = getPublicClient(srcChainSelector);

    // let latestBlockNumber = BigInt(await client.getBlockNumber());
    // Fetch the log by messageId
    // const srcBlockNumber = await getLogByMessageId(
    //     client,
    //     conceroRouters[srcChainSelector],
    //     messageId,
    //     latestBlockNumber,
    // ).then(log => BigInt(log.blockNumber));

    // // // Wait for the required confirmations
    // // while (latestBlockNumber - srcBlockNumber < confirmations) {
    // //     latestBlockNumber = BigInt(await client.getBlockNumber());
    // //     await sleep(3000);
    // // }
    // // Fetch the log again after confirmations

    const log = await fetchConceroMessage(client, conceroRouters[srcChainSelector], messageId, BigInt(srcBlockNumber));
    const parsedMessage = decodeConceroMessageLog(log.data);
    const { messageConfig: messageConfigFromLog, dstChainData, message } = parsedMessage;

    const messageBytes = encodeAbiParameters(
        ["bytes32", ClientMessageRequest],
        [
            messageId,
            {
                messageConfig: BigInt(messageConfigFromLog),
                dstChainData,
                message: keccak256(message),
            },
        ],
    );

    const recomputedMessageHashSum = keccak256(messageBytes);
    if (recomputedMessageHashSum !== messageHashSum) throw new Error(ErrorType.INVALID_HASHSUM);

    return packResult(messageId, recomputedMessageHashSum, BigInt(srcChainSelector));
}
async function test() {
    const OFFSET_VERSION = 248n; // uint8 (8 bits, highest bits of 256-bit number)
    const OFFSET_SRC_CHAIN_SELECTOR = 224n; // uint24 (24 bits)
    const OFFSET_DST_CHAIN_SELECTOR = 200n; // uint24 (24 bits)
    const OFFSET_MIN_SRC_CONF = 184n; // uint16 (16 bits)
    const OFFSET_MIN_DST_CONF = 168n; // uint16 (16 bits)
    const OFFSET_RELAYER_CONFIG = 160n; // uint8 (8 bits)
    const OFFSET_IS_CALLBACKABLE = 159n; // bool (1 bit)

    // Create a valid `messageConfig`
    const messageConfig =
        (1n << OFFSET_VERSION) | // version = 1
        (100n << OFFSET_SRC_CHAIN_SELECTOR) | // srcChainSelector = 100
        (1n << OFFSET_DST_CHAIN_SELECTOR) | // dstChainSelector = 1
        (2n << OFFSET_MIN_SRC_CONF) | // minSrcConfirmations = 2
        (1n << OFFSET_MIN_DST_CONF) | // minDstConfirmations = 1
        (3n << OFFSET_RELAYER_CONFIG) | // relayerConfig = 3
        (1n << OFFSET_IS_CALLBACKABLE); // isCallbackable = true

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
