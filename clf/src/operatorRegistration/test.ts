import { main } from "./index";

async function test() {
    const chainTypes = JSON.stringify([0, 1]);
    const operatorAddresses = JSON.stringify(["0x123", "0x456"]);
    const operatorAddress = "0x123";

    const inputArgs = ["", chainTypes, operatorAddresses, operatorAddress];

    try {
        const result = await main(inputArgs);
        console.log("Test Passed:", result);
    } catch (error) {
        console.error("Test Failed:", error.message);
    }
}

test();
