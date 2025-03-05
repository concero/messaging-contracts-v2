import "@nomicfoundation/hardhat-chai-matchers";
import { keccak256, parseUnits } from "ethers";
import { Address, encodeAbiParameters, zeroHash } from "viem";
import { privateKeyToAccount } from "viem/accounts";

import deployConceroClientExample from "../../deploy/ConceroClientExample";
import deployVerifier from "../../deploy/ConceroVerifier";
import deployMockCLFRouter from "../../deploy/MockCLFRouter";
import { deployContracts } from "../../tasks";
import { simulateCLFScript } from "../../tasks/clf";
import { getTestClient } from "../../utils";
import { ConceroMessageConfig } from "../../utils/ConceroMessageConfig";
import { encodedSrcChainData } from "./utils/encodeSrcChainData";

describe("sendMessage\n", async () => {
	it("should send and receiveMessage in test concero client", async () => {
		const hre = require("hardhat");

		// 	await simulateCLFScript(
		// 		__dirname + "/../../clf/dist/messageReport.js",
		// 		"messageReport",
		// 		[
		// 			zeroHash,
		// 			'0x000000010000000000000a000100010000000000000000000000000000000000',
		// 			'0xfba642d737b072ae1b63a8bd69c18a796554d7ef792b442a4504a3094350fae8',
		// 			'0x01038002863c0807b2f23315e8b322ce9772afa15ea0d7e4ec317c5506891ba8',
		// 			'0x000000000000000000000000ccccac597660eebf71b424415f874ee4c6b13d22000000000000000000000000000000000000000000000000000000000000004f',
		// 			'0xCCCcAC597660Eebf71b424415f874ee4c6b13D22',
		// 		],
		// 		{
		// 			CONCERO_VERIFIER_LOCALHOST: '0xa45F4A08eCE764a74cE20306d704e7CbD755D8a4',
		// 		},
		// 	);
		// }).timeout(0);
		//
		// return;
		// @dev deploy
		const mockClfRouter = await deployMockCLFRouter();
		const { address: conceroVerifierAddress } = await deployVerifier(hre);
		const { conceroRouter } = await deployContracts(mockClfRouter.address as Address);
		const conceroRouterAddress = conceroRouter.address;
		const conceroClientExample = await deployConceroClientExample(hre, {
			conceroRouter: conceroRouterAddress,
		});
		const conceroClientExampleAddress = conceroClientExample.address as Address;

		// @dev send message
		const testClient = getTestClient(
			privateKeyToAccount(`0x${process.env.LOCALHOST_DEPLOYER_PRIVATE_KEY}`),
		);
		const dstChainData = encodeAbiParameters(
			[
				{ name: "receiver", type: "address" },
				{ name: "gasLimit", type: "uint256" },
			],
			[conceroClientExampleAddress, 1_000_000n],
		);
		const operatorAddress = testClient.account.address;
		const message = encodeAbiParameters(
			[{ type: "string", name: "message" }],
			["Hello, world!"],
		);

		const messageConfig = new ConceroMessageConfig();
		messageConfig.setVersion(1);
		messageConfig.setSrcChainSelector(1n);
		messageConfig.setDstChainSelector(10n);
		messageConfig.setMinSrcConfirmations(1);
		messageConfig.setMinDstConfirmations(1);

		const sendMessageHash = await testClient.writeContract({
			address: conceroRouterAddress,
			abi: conceroRouter.abi,
			functionName: "conceroSend",
			args: [messageConfig.hexConfig, dstChainData, message],
			value: parseUnits("0.1", 18),
		});

		const { status: sendMessageStatus, logs: sendMessageLogs } =
			await testClient.waitForTransactionReceipt({
				hash: sendMessageHash,
			});
		if (sendMessageStatus !== "success")
			throw new Error(`sendMessage failed with status: ${sendMessageStatus}`);

		const messageId = sendMessageLogs[0].topics[2];
		const messageHashSum = keccak256(message);
		const srcChainData = encodedSrcChainData(
			testClient.account.address,
			await testClient.getBlockNumber(),
		);

		await simulateCLFScript(
			__dirname + "/../../clf/dist/messageReport.js",
			"messageReport",
			[
				zeroHash,
				messageConfig.hexConfig,
				messageId,
				messageHashSum,
				srcChainData,
				operatorAddress,
			],
			{
				CONCERO_VERIFIER_LOCALHOST: conceroVerifierAddress,
			},
		);
	}).timeout(0);
});
