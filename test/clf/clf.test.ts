import deployMockCLFRouter from "../../deploy/MockCLFRouter";
import "@nomicfoundation/hardhat-chai-matchers";
import { getTestClient } from "../../utils";
import { privateKeyToAccount } from "viem/accounts";
import { deployContracts } from "../../tasks";
import deployConceroClientExample from "../../deploy/ConceroClientExample";
import { parseUnits } from "ethers";
import { simulateCLFScript } from "../../tasks/clf";
import { zeroHash, Address } from "viem";
import { ConceroMessageConfig } from "../../utils/ConceroMessageConfig";
import { encodedSrcChainData } from "./utils/encodeSrcChainData";

describe("sendMessage\n", async () => {
    it("should send and receiveMessage in test concero client", async () => {
        const hre = require("hardhat");
        const mockClfRouter = await deployMockCLFRouter();
        const { conceroRouter } = await deployContracts(mockClfRouter.address as Address);
        const conceroRouterAddress = conceroRouter.address;
        const conceroClientExample = await deployConceroClientExample(hre, { conceroRouter: conceroRouterAddress });
        const conceroClientExampleAddress = conceroClientExample.address as Address;

        const testClient = getTestClient(privateKeyToAccount(`0x${process.env.LOCALHOST_DEPLOYER_PRIVATE_KEY}`));
        const receiver = testClient.account?.address;

        const sendMessageHash = await testClient.writeContract({
            address: conceroClientExampleAddress,
            abi: conceroClientExample.abi,
            functionName: "sendConceroMessage",
            args: [receiver],
            value: parseUnits("0.1", 18),
        });

        const sendMessageStatus = (await testClient.waitForTransactionReceipt({ hash: sendMessageHash })).status;
        if (sendMessageStatus !== "success") throw new Error(`sendMessage failed with status: ${sendMessageStatus}`);

        const config = 0n;
        const jsCodeHash = zeroHash;
        const messageId = zeroHash;
        const messageHashSum = zeroHash;
        const srcChainData = encodedSrcChainData(testClient.account.address, await testClient.getBlockNumber());
        const operatorAddress = testClient.account.address;

        const messageConfig = new ConceroMessageConfig();
        messageConfig.setVersion(1);
        messageConfig.setSrcChainSelector(1n);
        messageConfig.setMinSrcConfirmations(1);
        messageConfig.setMinDstConfirmations(1);
        messageConfig.setDstChainSelector(2n);

        await simulateCLFScript(__dirname + "/../../clf/dist/messageReport.js", "messageReport", [
            jsCodeHash,
            messageConfig.hexConfig,
            messageId,
            messageHashSum,
            srcChainData,
            operatorAddress,
        ]);
    }).timeout(0);
});
