import { task } from "hardhat/config";
import { conceroNetworks } from "../constants";

function getHashSum(sourceCode: string) {
    const hash = require("crypto").createHash("sha256");
    hash.update(sourceCode, "utf8");
    return hash.digest("hex");
}

task("test-script", "A test script").setAction(async (taskArgs, hre) => {
    console.log(hre.network.name);
    const chain = conceroNetworks[hre.network.name];

    console.log("Running test-script");
    // const [conceroProxy, conceroProxyAlias] = getEnvAddress("infraProxy", chain.name);
    // console.log(conceroProxy, conceroProxyAlias);

    // await deployProxyAdmin(hre, ProxyEnum.parentPool);
    // await deployTransparentProxy(hre, ProxyEnum.parentPool);
    // await upgradeProxyImplementation(hre, ProxyEnum.parentPool, false);
});

export default {};
