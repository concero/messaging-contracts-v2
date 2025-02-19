import { configureDotEnv } from "../../../utils";

configureDotEnv("./test/operator");
process.env.HARDHAT_NETWORK = "localhost";
const hre = require("hardhat");
