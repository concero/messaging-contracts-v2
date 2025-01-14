// import { encodeAbiParameters } from "viem";
// import { CLFType, runCLFSimulation } from "../../utils/runCLFSimulation";
// import { conceroMessageAbi } from "./utils/conceroMessageAbi";
// import { IConceroMessageRequest } from "./utils/types";
// import { getEnvVar } from "../../utils";
//
// describe("Concero Router", () => {
//     it("Should deploy the contract and call sendMessage", async function () {
//         const { abi: conceroRouterAbi } = await import("../../../v2-operators/src/abi/ConceroRouter.json");
//
//         const message: IConceroMessageRequest = {
//             id: "0x262f761b31058aa24a07861b230c9c50821ae91574fc94b15e9423160f46addd",
//             feeToken: "0x0000000000000000000000000000000000000000",
//             srcChainSelector: BigInt(process.env.CL_CCIP_CHAIN_SELECTOR_BASE_SEPOLIA),
//             dstChainSelector: getEnvVar("CL_CCIP_CHAIN_SELECTOR_ARBITRUM_SEPOLIA"),
//             receiver: getEnvVar("CONCERO_DEMO_CLIENT_ARBITRUM_SEPOLIA"),
//             tokenAmounts: [{ token: "0x0000000000000000000000000000000000000000", amount: 10000000n }],
//             sender: "0xdddddb8a8e41c194ac6542a0ad7ba663a72741e0",
//             relayers: [0],
//             data: encodeAbiParameters([{ type: "string", name: "data" }], ["Hello world!"]),
//             extraArgs: encodeAbiParameters([{ type: "uint32", name: "extraArgs" }], [300000n]),
//         };
//
//         const encodedMessage = encodeAbiParameters(conceroMessageAbi, [
//             {
//                 srcChainSelector: message.srcChainSelector,
//                 dstChainSelector: message.dstChainSelector,
//                 receiver: message.receiver,
//                 sender: message.sender,
//                 tokenAmounts: message.tokenAmounts,
//                 relayers: message.relayers,
//                 data: message.data,
//                 extraArgs: message.extraArgs,
//             },
//         ]);
//
//         const results = await runCLFSimulation(CLFType.messageReport, ["0x0", "0x0", message.id, encodedMessage], {
//             print: false,
//             rebuild: true,
//         });
//
//         console.log(results);
//     });
// });
