import { main } from "./index";

async function test() {
    const chainTypes = [0, 1];
    const operatorAddresses = ["0x123", "0x456"];
    const actions = [0, 1];
    const requester = "0x123";

    const inputArgs = ["", chainTypes, actions, operatorAddresses, requester];

    try {
        const result = await main(inputArgs);
        console.log("Test Passed:", result);
    } catch (error) {
        console.error("Test Failed:", error.message);
    }
}

test();
