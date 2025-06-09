import { task } from "hardhat/config";
import { deployPauseDummy } from "../deploy";

task("deploy-pause", "").setAction(async taskArgs => {
	const hre = require("hardhat");
	await deployPauseDummy(hre);
});

export default {};
