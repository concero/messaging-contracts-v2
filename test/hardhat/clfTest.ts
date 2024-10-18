import { cNetworks, networkEnvKeys } from "../../constants";
import { getClients, getEnvVar } from "../../utils";
import { approve } from "./utils/approve";
import { encodeAbiParameters, parseUnits } from "viem";
import { decodeLogWrapper } from "./utils/decodeLogWrapper";
import { CLFType, runCLFSimulation } from "../../utils/runCLFSimulation";

const hre = require("hardhat");

describe("Concero Router", () => {
    let deploymentAddress = "0x23494105b6B8cEaA0eB9c051b7e4484724641821";

    // it("Should deploy Concero Router", async function () {
    //     const deployment = await deployConceroRouter(hre);
    //     deploymentAddress = deployment.address;
    // });

    it("Should deploy the contract and call sendMessage", async function () {
        const { abi: conceroRouterAbi } = await import(
            "../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
        );

        const { publicClient, walletClient } = getClients(cNetworks.localhost.viemChain);
        const feeToken = getEnvVar(`USDC_${networkEnvKeys["base"]}`);
        const messageRequest = {
            feeToken,
            message: {
                dstChainSelector: getEnvVar("CL_CCIP_CHAIN_SELECTOR_ARBITRUM_SEPOLIA"),
                receiver: walletClient.account.address,
                tokenAmounts: [],
                relayers: [],
                data: walletClient.account.address,
                extraArgs: "0x01010",
            },
        };

        await approve(feeToken, deploymentAddress, parseUnits("1", 6), walletClient, publicClient);

        const hash = await walletClient.writeContract({
            address: deploymentAddress,
            abi: conceroRouterAbi,
            functionName: "sendMessage",
            account: walletClient.account,
            args: [messageRequest],
            chain: cNetworks.localhost.viemChain,
        });

        console.log("Message sent with hash:", hash);
        const { status, logs } = await publicClient.waitForTransactionReceipt({ hash });

        if (status != "success") {
            throw new Error(`Transaction failed`);
        }

        const decodedLogs = logs.map(log => decodeLogWrapper(conceroRouterAbi, log));
        const messageLog = decodedLogs.find(log => log?.eventName === "ConceroMessage");

        if (!messageLog) {
            throw new Error(`ConceroMessage log not found`);
        }

        const message = {
            id: messageLog.args.id,
            srcChainSelector: BigInt(process.env.CL_CCIP_CHAIN_SELECTOR_LOCALHOST),
            dstChainSelector: BigInt(messageLog.args.message.dstChainSelector),
            srcChainBlockNumber: BigInt(process.env.LOCALHOST_FORK_LATEST_BLOCK_NUMBER),
            receiver: messageLog.args.message.receiver,
            tokenAmounts: messageLog.args.message.tokenAmounts,
            relayers: messageLog.args.message.relayers,
            data: messageLog.args.message.data,
            extraArgs: messageLog.args.message.extraArgs,
        };

        const encodedMessage = encodeAbiParameters(
            [
                { name: "id", type: "bytes32" },
                { name: "srcChainSelector", type: "uint64" },
                { name: "dstChainSelector", type: "uint64" },
                { name: "srcChainBlockNumber", type: "uint64" },
                { name: "receiver", type: "address" },
                { name: "tokenAmounts", type: "tuple(address, uint256)[]" },
                { name: "relayers", type: "uint8[]" },
                { name: "data", type: "bytes" },
                { name: "extraArgs", type: "bytes" },
            ],
            [
                message.id,
                message.srcChainSelector,
                message.dstChainSelector,
                message.srcChainBlockNumber,
                message.receiver,
                message.tokenAmounts,
                message.relayers,
                message.data,
                message.extraArgs,
            ],
        );

        const results = await runCLFSimulation(CLFType.requestReport, ["0x0", "0x0", encodedMessage], {
            print: false,
            rebuild: true,
        });

        console.log(results);
    });
});
