import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { task } from "hardhat/config";
import deployRouter from "../deploy/ConceroRouter";
import deployVerifier from "../deploy/ConceroVerifier";
import { compileContracts, getEnvVar, getFallbackClients } from "../utils";
import {
    Namespaces as verifierNamespaces,
    PriceFeedSlots as verifierPriceFeedSlots,
} from "../constants/storage/ConceroVerifierStorage";
import {
    Namespaces as routerNamespaces,
    PriceFeedSlots as routerPriceFeedSlots,
} from "../constants/storage/ConceroRouterStorage";
import { conceroNetworks } from "../constants";
import { ConceroNetwork } from "../types/ConceroNetwork";
import { parseUnits, zeroHash } from "viem";
import deployMockCLFRouter from "../deploy/MockCLFRouter";
import deployConceroClientExample from "../deploy/ConceroClientExample";

async function operatorSetup() {
    const hre: HardhatRuntimeEnvironment = require("hardhat");
    await compileContracts({ quiet: true });
    const operatorAddress = getEnvVar("TESTNET_OPERATOR_ADDRESS");
    const userAddress = getEnvVar("TESTNET_USER_ADDRESS");

    const conceroVerifier = await deployVerifier(hre);
    const conceroRouter = await deployRouter(hre);
    // await setVerifierVariables(hre);
    await setVerifierPriceFeeds(conceroVerifier.address, conceroNetworks.localhost);
    await setRouterPriceFeeds(conceroRouter.address, conceroNetworks.localhost);

    const conceroClientExample = await deployConceroClientExample(hre);
    const mockCLFRouter = await deployMockCLFRouter(hre);

    await sendConceroMessage(conceroClientExample.address, conceroNetworks.localhost);
}

async function sendConceroMessage(conceroClientAddress: string, chain: ConceroNetwork) {
    const { abi: exampleClientAbi } = await import(
        "../artifacts/contracts/ConceroClient/ConceroClientExample.sol/ConceroClientExample.json"
    );

    const { publicClient, walletClient, account } = getFallbackClients(chain);

    const txHash = await walletClient.writeContract({
        chain: chain.viemChain,
        address: conceroClientAddress,
        abi: exampleClientAbi,
        functionName: "sendConceroMessage",
        args: [],
        account,
        value: parseUnits("0.001", 18),
    });

    console.log(`Sent concero message with txHash ${txHash}`);
}

async function setVerifierPriceFeeds(conceroVerifierAddress: string, chain: ConceroNetwork) {
    const chainSelector = 1n;
    const nativeUsdRate = 2000e18;
    const nativeNativeRate = 1e18;
    const lastGasPrice = 1_000_000n;

    const { abi: conceroVerifierAbi } = await import(
        "../artifacts/contracts/ConceroVerifier/ConceroVerifier.sol/ConceroVerifier.json"
    );
    const { publicClient, walletClient, account } = getFallbackClients(chain);

    const toBytes32 = (value: BigInt) => `0x${value.toString(16).padStart(64, "0")}`;

    await walletClient.writeContract({
        chain: chain.viemChain,
        address: conceroVerifierAddress,
        abi: conceroVerifierAbi,
        functionName: "setStorage",
        args: [
            verifierNamespaces.PRICEFEED,
            BigInt(verifierPriceFeedSlots.nativeUsdRate),
            zeroHash,
            BigInt(nativeUsdRate),
        ],
        account,
    });

    await walletClient.writeContract({
        chain: chain.viemChain,
        address: conceroVerifierAddress,
        abi: conceroVerifierAbi,
        functionName: "setStorage",
        args: [
            verifierNamespaces.PRICEFEED,
            BigInt(verifierPriceFeedSlots.lastGasPrices),
            toBytes32(chainSelector),
            lastGasPrice,
        ],
        account,
    });

    await walletClient.writeContract({
        chain: chain.viemChain,
        address: conceroVerifierAddress,
        abi: conceroVerifierAbi,
        functionName: "setStorage",
        args: [
            verifierNamespaces.PRICEFEED,
            BigInt(verifierPriceFeedSlots.nativeNativeRates),
            toBytes32(chainSelector),
            nativeNativeRate,
        ],
        account,
    });
}

async function setRouterPriceFeeds(conceroRouterAddress: string, chain: ConceroNetwork) {
    const chainSelector = 1n;
    const nativeUsdRate = 2000e18;
    const nativeNativeRate = 1e18;
    const lastGasPrice = 1_000_000n;

    const { abi: conceroRouterAbi } = await import(
        "../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
    );
    const { publicClient, walletClient, account } = getFallbackClients(chain);

    const toBytes32 = (value: BigInt) => `0x${value.toString(16).padStart(64, "0")}`;

    await walletClient.writeContract({
        chain: chain.viemChain,
        address: conceroRouterAddress,
        abi: conceroRouterAbi,
        functionName: "setStorage",
        args: [routerNamespaces.PRICEFEED, BigInt(routerPriceFeedSlots.nativeUsdRate), zeroHash, BigInt(nativeUsdRate)],
        account,
    });

    await walletClient.writeContract({
        chain: chain.viemChain,
        address: conceroRouterAddress,
        abi: conceroRouterAbi,
        functionName: "setStorage",
        args: [
            routerNamespaces.PRICEFEED,
            BigInt(routerPriceFeedSlots.lastGasPrices),
            toBytes32(chainSelector),
            lastGasPrice,
        ],
        account,
    });

    await walletClient.writeContract({
        chain: chain.viemChain,
        address: conceroRouterAddress,
        abi: conceroRouterAbi,
        functionName: "setStorage",
        args: [
            routerNamespaces.PRICEFEED,
            BigInt(routerPriceFeedSlots.nativeNativeRates),
            toBytes32(chainSelector),
            nativeNativeRate,
        ],
        account,
    });
}

task("operator-setup", "Setup the operator").setAction(async () => {
    await operatorSetup();
});

export default operatorSetup;
