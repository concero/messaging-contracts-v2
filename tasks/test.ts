import { task } from "hardhat/config";

task("test-script", "A test script").setAction(async taskArgs => {
	console.log(hre.network.name);

	console.log("Running test-script");
});

export default {};
