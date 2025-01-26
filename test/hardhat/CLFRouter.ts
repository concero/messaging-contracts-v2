// import { conceroNetworks } from "../../constants";
// import { getEnvAddress, getFallbackClients } from "../../utils";
// import { privateKeyToAccount } from "viem/accounts";
//
// const hre = require("hardhat");
//
// const { publicClient, walletClient, account } = getFallbackClients(
//     conceroNetworks[hre.network.name],
//     privateKeyToAccount("0x" + process.env.TEST_DEPLOYER_PRIVATE_KEY),
// );
//
// describe("CLF Router", async () => {
//     // before(async function () {
//     //     const { deployer } = await hre.getNamedAccounts();
//     //     deployerAddress = deployer;
//     //
//     //     await hre.network.provider.send("hardhat_setBalance", [deployer, "0x1000000000000000000000000"]);
//     //
//     //     const { address } = await deployVerifier(hre);
//     //     ConceroVerifier.sol = address;
//     // });
//     //
//     // it("Should set allowed operator to deployer address", async function () {
//     //     const { abi: CLFRouterAbi } = await import("../../artifacts/contracts/ConceroVerifier.sol/ConceroVerifier.sol.sol/ConceroVerifier.sol.json");
//     //
//     //     // Call registerOperator from the owner (deployer) account
//     //     const { request: registerOperatorRequest } = await publicClient.simulateContract({
//     //         address: ConceroVerifier.sol,
//     //         abi: CLFRouterAbi,
//     //         functionName: "registerOperator",
//     //         account,
//     //         args: [deployerAddress],
//     //     });
//     //
//     //     const registerHash = await walletClient.writeContract(registerOperatorRequest);
//     //     console.log("Operator registered with hash:", registerHash);
//     // });
//     //
//     it("Should call requestCLFMessageReport", async function () {
//         const { abi: CLFRouterAbi } = await import("../../artifacts/contracts/ConceroVerifier.sol/ConceroVerifier.sol.sol/ConceroVerifier.sol.json");
//
//         const [ConceroVerifier.sol] = getEnvAddress("clfRouterProxy", hre.network.name);
//         // Define the message structure
//         const message = {
//             srcChainSelector: 1, // Example value
//             dstChainSelector: 2, // Example value
//             receiver: account.address, // Example receiver
//             sender: account.address, // Example sender
//             tokenAmounts: [], // Example token amounts, empty for now
//             relayers: [], // Example relayers, empty for now
//             data: "0x", // Example data, empty for now
//             extraArgs: "0x", // Example extra args, empty for now
//         };
//
//         // Generate a messageId for the request
//         const messageId = hre.ethers.utils.keccak256(
//             hre.ethers.utils.defaultAbiCoder.encode(
//                 ["address", "uint64", "address"],
//                 [account.address, 1, account.address],
//             ),
//         );
//
//         // Call requestCLFMessageReport from the operator (deployer) account
//         const { request: requestMessageReportRequest } = await publicClient.simulateContract({
//             address: ConceroVerifier.sol,
//             abi: CLFRouterAbi,
//             functionName: "requestCLFMessageReport",
//             account,
//             args: [messageId, message],
//         });
//
//         const messageReportHash = await walletClient.writeContract(requestMessageReportRequest);
//         console.log("Message report requested with hash:", messageReportHash);
//
//         // // Check that the message status is updated to "Pending"
//         // const clfRequestStatus = await publicClient.readContract({
//         //     address: ConceroVerifier.sol,
//         //     abi: CLFRouterAbi,
//         //     functionName: "s_clfRequestStatusByConceroId",
//         //     args: [messageId],
//         // });
//
//         // CLFRequestStatus.Pending is assumed to be 1 in your contract, adjust if necessary
//         // expect(clfRequestStatus).to.equal(1); // Pending status
//     });
// });
