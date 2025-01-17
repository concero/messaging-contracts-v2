import { encodeAbiParameters } from "viem";
import { main } from "./index";
import { INTERNAL_MESSAGE_CONFIG_OFFSETS as OFFSETS } from "./constants/bitOffsets";
const INTERNAL_MESSAGE_CONFIG = 452312875543266115865028960902504686384011240534399916070534913969327439872n;

async function test() {
    const messageConfig =
        (1n << BigInt(OFFSETS.VERSION)) | // version = 1
        (1n << BigInt(OFFSETS.SRC_CHAIN)) | // srcChainSelector = 1
        (8453n << BigInt(OFFSETS.DST_CHAIN)) | // dstChainSelector = 8453
        (1n << BigInt(OFFSETS.MIN_SRC_CONF)) | // minSrcConfirmations = 1
        (1n << BigInt(OFFSETS.MIN_DST_CONF)) | // minDstConfirmations = 1
        (0n << BigInt(OFFSETS.RELAYER)) | // relayerConfig = 0
        (0n << BigInt(OFFSETS.CALLBACKABLE)); // isCallbackable = false

    const CURRENT_MESSAGE_CONFIG = messageConfig;
    // logInternalMessageConfig(INTERNAL_MESSAGE_CONFIG);

    const srcChainData = {
        sender: "0x1234567890123456789012345678901234567890", // example sender address
        blockNumber: "0x1234", // example block number
    };

    const encodedSrcChainData = encodeAbiParameters(
        [
            {
                type: "tuple",
                components: [
                    { name: "sender", type: "address" },
                    { name: "blockNumber", type: "uint256" },
                ],
            },
        ],
        [
            {
                sender: "0x1234567890123456789012345678901234567890",
                blockNumber: 0x1234n,
            },
        ],
    );

    const inputArgs = [
        "0x1234", // Dummy hash
        "0x" + CURRENT_MESSAGE_CONFIG.toString(16).padStart(64, "0"),
        "0x0000000000000000000000000000000000000000000000000000000000000456", // messageId
        "0x0000000000000000000000000000000000000000000000000000000000000789", // messageHashSum
        encodedSrcChainData, // srcChainData
        "0x1234567890123456789012345678901234567890", // operatorAddress (valid ethereum address)
    ];

    await main(inputArgs);
}

test();

function logInternalMessageConfig(config: bigint) {
    console.log("Version:", Number(config >> 248n));
    console.log("Source Chain:", Number((config >> 224n) & 0xffffffn));
    console.log("Dest Chain:", Number((config >> 192n) & 0xffffffn));
    console.log("Min Src Conf:", Number((config >> 176n) & 0xffffn));
    console.log("Min Dst Conf:", Number((config >> 160n) & 0xffffn));
    console.log("Relayer Config:", Number((config >> 152n) & 0xffn));
    console.log("Callbackable:", Number((config >> 151n) & 1n));
    console.log("Fee Token:", Number((config >> 143n) & 0xffn));
}
