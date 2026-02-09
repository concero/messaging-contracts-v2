import { task } from "hardhat/config";

import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { deployRouterTask } from "./deployRouter/deployRouterTask";
import { deployCreValidatorLibTask } from "./cre/deployCreValidatorLib.task";
import { deployRelayerLibTask } from "./relayer/deployRelayer.task";
import { getDeployerBalance } from "./getDeployerBalance.task";

import { mainnetRelayer } from "./relayer/setRelayerLibVars";
import { sendNativeTokenTrezor } from "./nativeSender/sendNativeTokenTrezor.task";
import { log } from "@concero/contract-utils";
import { formatUnits } from "viem";

task("deploy-messaging", "Deploy ConceroRouter").setAction(
	async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		await deployRouterTask({ implementation: true, proxy: true }, hre);
		await deployCreValidatorLibTask({ implementation: true, proxy: true }, hre);
		await deployRelayerLibTask({ implementation: true, proxy: true, vars: true }, hre);

		const deployerBalance = await getDeployerBalance(hre);
		const amountToSend = formatUnits((deployerBalance * 30n) / 100n, 18);

		log(
			`Deployer balance: ${formatUnits(deployerBalance, 18)}. Sending ${amountToSend}`,
			"deploy-messaging",
		);
		await sendNativeTokenTrezor({ recipient: mainnetRelayer, amount: amountToSend }, hre);
	},
);

export default {};
