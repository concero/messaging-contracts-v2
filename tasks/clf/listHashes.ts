import { task } from "hardhat/config";
import getHashSum from "../../utils/getHashSum";

task("list-hashes", "Lists hashes for JS code").setAction(async taskArgs => {
    console.log("Eval.js:", getHashSum("../../clf/dist/eval.ts"));
    // console.log("DST:", getHashSum(secrets.DST_JS));
});

export default {};
