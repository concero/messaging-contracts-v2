import "@nomicfoundation/hardhat-chai-matchers";
import { switchFork } from "./utils/switchFork";
import deployConceroRouter from "../../deploy/ConceroRouter";

const hre = require("hardhat");

describe("emit event and run clf", () => {
    it("should emit event", async () => {
        await switchFork("base");

        await deployConceroRouter(hre);
    });
});
