import { task } from "hardhat/config";

import { ProxyEnum } from "../constants";
import { err } from "../utils";
import { changeProxyAdminOwner } from "./utils";

async function changeProxyAdminOwnerTask(taskArgs: any) {
	let type: ProxyEnum;

	if (taskArgs.type === "router") {
		type = ProxyEnum.routerProxy;
	} else if (taskArgs.type === "verifier") {
		type = ProxyEnum.verifierProxy;
	} else if (taskArgs.type === "priceFeed") {
		type = ProxyEnum.priceFeedProxy;
	} else {
		err("Invalid type", "changeProxyAdminOwnerTask");
		return;
	}

	await changeProxyAdminOwner(taskArgs.chains, taskArgs.new, type);
}

task("change-proxy-admin-owner", "Change the admin owner of a proxy")
	.addParam("new", "The address of the new owner")
	.addParam("chains", "Comma separated list of chains", "")
	.addParam("type", "The type of proxy to change the admin owner of", "")
	.setAction(async taskArgs => {
		await changeProxyAdminOwnerTask(taskArgs);
	});

export { changeProxyAdminOwnerTask };
