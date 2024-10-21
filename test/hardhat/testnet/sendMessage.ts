import { IConceroMessageRequest } from "../utils/types";
import { getClients, getEnvVar } from "../../../utils";
import { conceroNetworks } from "../../../constants";
import { getViemAccount } from "../../../utils/getViemClients";
import { sendConceroRouterMessageBase } from "../base/sendConceroRouterMessageBase";

describe("ConceroRouterSendMessage", () => {
    it("Should send message", async function () {
        const conceroNetwork = conceroNetworks.baseSepolia;

        const { walletClient, publicClient } = getClients(
            conceroNetworks.viemChain,
            conceroNetwork.url,
            getViemAccount("testnet", "deployer"),
        );

        const messageReq: IConceroMessageRequest = {
            feeToken: getEnvVar("CONCERO_CLF_ROUTER"),
            dstChainSelector: getEnvVar("CL_CCIP_CHAIN_SELECTOR_ARBITRUM_SEPOLIA"),
            data: "0x01",
            tokenAmounts: [],
            relayers: [],
            extraArgs: "",
        };

        const res = await sendConceroRouterMessageBase({
            conceroRouterAddress: getEnvVar("CONCERO_ROUTER_PROXY_BASE_SEPOLIA"),
            walletClient,
            publicClient,
            messageReq,
        });

        console.log("logs: ", res.logs);
    });
});
