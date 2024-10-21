import { IConceroMessageRequest } from "../utils/types";
import { getEnvVar, getWallet } from "../../../utils";
import { conceroNetworks } from "../../../constants";
import { sendRouterMessage } from "../base/sendRouterMessage";

describe("ConceroRouterSendMessage", () => {
    it("Should send message", async function () {
        const chain = conceroNetworks.baseSepolia;
        const receiver = getWallet("testnet", "deployer", "address");

        const message: IConceroMessageRequest = {
            feeToken: "0x0000000000000000000000000000000000000000",
            dstChainSelector: getEnvVar("CL_CCIP_CHAIN_SELECTOR_ARBITRUM_SEPOLIA"),
            receiver,
            tokenAmounts: [],
            relayers: [],
            data: "0x01",
            extraArgs: "",
        };

        const { hash, logs } = await sendRouterMessage(chain, message, 50_000n);
    });
});
