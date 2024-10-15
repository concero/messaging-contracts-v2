import "@nomicfoundation/hardhat-chai-matchers";
import { ethers } from "hardhat";

describe("emit event and run clf", () => {
    it("should emit event", async () => {
        const ContractFactory = await ethers.getContractFactory("Test");

        const contract = await ContractFactory.deploy();

        await contract.deployed();

        const tx = await contract.emitEvent();

        const receipt = await tx.wait();

        console.log(receipt.events);
    });
});
