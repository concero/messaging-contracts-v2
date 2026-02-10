import { task } from "hardhat/config";

import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { deployRelayerLibTask } from "./relayer/deployRelayer.task";
import { getDeployerBalance } from "./getDeployerBalance.task";

import { mainnetRelayer } from "./relayer/setRelayerLibVars";
import { sendNativeTokenTrezor } from "./nativeSender/sendNativeTokenTrezor.task";
import { log } from "@concero/contract-utils";
import { formatUnits } from "viem";

task("deploy-messaging", "Deploy ConceroRouter").setAction(
	async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		// await deployPriceFeedTask({ implementation: true, proxy: true }, hre);

		let deployerBalance = await getDeployerBalance(hre);
		let amountToSend = formatUnits((deployerBalance * 10n) / 100n, 18);

		// log(
		// 	`Deployer balance: ${formatUnits(deployerBalance, 18)}. Sending ${amountToSend} to price feed updater`,
		// 	"deploy-messaging",
		// );
		//
		// await sendNativeTokenTrezor(
		// 	{ recipient: getEnvVar("MAINNET_FEED_UPDATER_ADDRESS"), amount: amountToSend },
		// 	hre,
		// );

		// await deployRouterTask({ implementation: true, proxy: true }, hre);
		// await deployCreValidatorLibTask({ implementation: true, proxy: true }, hre);
		await deployRelayerLibTask({ implementation: true, proxy: true, vars: true }, hre);

		deployerBalance = await getDeployerBalance(hre);
		amountToSend = formatUnits((deployerBalance * 30n) / 100n, 18);

		log(
			`Deployer balance: ${formatUnits(deployerBalance, 18)}. Sending ${amountToSend} to relayer`,
			"deploy-messaging",
		);
		await sendNativeTokenTrezor({ recipient: mainnetRelayer, amount: amountToSend }, hre);
	},
);

export default {};
