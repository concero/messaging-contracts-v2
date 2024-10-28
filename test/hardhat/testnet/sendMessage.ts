import { IConceroMessageRequest } from "../utils/types";
import { getEnvVar } from "../../../utils";
import { conceroNetworks } from "../../../constants";
import { sendRouterMessage } from "../base/sendRouterMessage";
import { encodeAbiParameters } from "viem";

describe("ConceroRouterSendMessage", () => {
    it("Should send message", async function () {
        const chain = conceroNetworks.baseSepolia;

        const message: IConceroMessageRequest = {
            feeToken: "0x0000000000000000000000000000000000000000",
            dstChainSelector: getEnvVar("CL_CCIP_CHAIN_SELECTOR_ARBITRUM_SEPOLIA"),
            receiver: getEnvVar("CONCERO_DEMO_CLIENT_ARBITRUM_SEPOLIA"),
            tokenAmounts: [{ token: "0x0000000000000000000000000000000000000000", amount: 10000000n }],
            relayers: [0],
            data: encodeAbiParameters([{ type: "string", name: "data" }], ["Hello world!"]),
            extraArgs: encodeAbiParameters(
                [
                    {
                        components: [
                            {
                                name: "gasLimit",
                                type: "uint32",
                            },
                        ],
                        name: "extraArgs",
                        type: "tuple",
                    },
                ],
                [{ gasLimit: 300000n }],
            ),
        };

        await sendRouterMessage(chain, message, 50_000n);
    });
});
