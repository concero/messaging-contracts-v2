import { configureDotEnv } from "./configureDotEnv";

configureDotEnv("./test/operator");
process.env.TENDERLY_AUTOMATIC_VERIFICATION = "false"; // Force Tenderly verification to false

require("hardhat");
