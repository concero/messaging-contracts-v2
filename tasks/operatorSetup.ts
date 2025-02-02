import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { task } from "hardhat/config";
import deployRouter from "../deploy/ConceroRouter";
import deployVerifier from "../deploy/ConceroVerifier";
import { getEnvVar, getFallbackClients } from "../utils";
import { setVerifierVariables } from "./deployVerifier";
import { Namespaces, PriceFeedSlots } from "../constants/storage/ConceroVerifierStorage";
import { conceroNetworks } from "../constants";
import { toBytes } from "viem";
import { ConceroNetwork } from "../types/ConceroNetwork";
import { encodeBytes32String } from "ethers";
import { clf } from ".";
import { zeroHash } from "viem";

async function operatorSetup() {
    const operatorAddress = getEnvVar("TESTNET_OPERATOR_ADDRESS");
    const hre: HardhatRuntimeEnvironment = require("hardhat");
    const conceroVerifier = await deployVerifier(hre);
    await setVerifierVariables(hre);
    await deployRouter(hre);

    await setVerifierPriceFeeds(conceroVerifier.address, conceroNetworks.localhost);
}

async function setVerifierPriceFeeds(conceroVerifierAddress: string, chain: ConceroNetwork) {
    const chainSelector = 1;
    const nativeUsdRate = 100n;
    const lastGasPrice = 200;

    const { abi: conceroVerifierAbi } = await import(
        "../artifacts/contracts/ConceroVerifier/ConceroVerifier.sol/ConceroVerifier.json"
    );
    const { publicClient, walletClient, account } = getFallbackClients(chain);

    const args = [Namespaces.PRICEFEED, zeroHash, zeroHash, nativeUsdRate];
    const txHash = await walletClient.writeContract({
        chain: chain.viemChain,
        address: conceroVerifierAddress,
        abi: conceroVerifierAbi,
        functionName: "setStorage",
        args,
        account,
    });

    // await conceroVerifier.setStorage(Namespaces.PRICEFEED, PriceFeedSlots.nativeUsdRate, 0n, nativeUsdRate);
    // await conceroVerifier.setStorage(Namespaces.PRICEFEED, PriceFeedSlots.lastGasPrices, chainSelector, lastGasPrice);
    // await conceroVerifier.setStorage(Namespaces.PRICEFEED, PriceFeedSlots.nativeNativeRates, chainSelector, 1e18);
}

task("operator-setup", "Setup the operator").setAction(async () => {
    await operatorSetup();
});

export default operatorSetup;
