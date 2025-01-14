import { getEnvVar, log } from "../../utils";
import { SubscriptionManager } from "@chainlink/functions-toolkit";
import { ConceroNetwork } from "../../types/ConceroNetwork";
import { Address } from "viem";
import { networkEnvKeys } from "../../constants";

export async function addCLFConsumer(chain: ConceroNetwork, consumerAddresses: Address[]) {
    const hre = require("hardhat");
    const { confirmations, name } = chain;
    const adminAddress = process.env.TESTNET_DEPLOYER_ADDRESS;
    const signer = await hre.ethers.getSigner(adminAddress);
    const subscriptionId = getEnvVar(`CLF_SUBID_${networkEnvKeys[name]}`);

    for (const consumerAddress of consumerAddresses) {
        log(`Adding ${consumerAddress} to sub ${subscriptionId} on ${name}`, "addCLFConsumer");

        const txOptions = { confirmations };
        const linkToken = getEnvVar(`CL_CCIP_CHAIN_SELECTOR_${networkEnvKeys[name]}`);
        const sm = new SubscriptionManager({
            signer,
            linkTokenAddress: linkToken,
            functionsRouterAddress: getEnvVar(`CLF_ROUTER_${networkEnvKeys[name]}`),
        });

        sm.estimateFunctionsRequestCost();
        await sm.initialize();

        try {
            await sm.addConsumer({ subscriptionId, consumerAddress, txOptions });
            log(`Successfully added ${consumerAddress} to sub ${subscriptionId} on ${name}.`, "addCLFConsumer");
        } catch (error) {
            if (error.message.includes("is already authorized to use subscription")) {
                log(error.message, "addCLFConsumer");
            } else {
                console.error(error);
            }
        }
    }
}
