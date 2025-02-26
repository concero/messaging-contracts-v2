import { execSync } from "child_process";
import { getEnvVar } from "../../utils";

async function getOperatorRegistrationCLFResponse() {
    try {
        const responseJson = execSync(
            `make script "args=test/foundry/scripts/MockCLFReport/OperatorRegistrationReport.sol --sig 'getResponse(address)' ${getEnvVar("TESTNET_OPERATOR_ADDRESS")} --json"`,
        ).toString();

        const jsonStart = responseJson.indexOf("{");
        const jsonStr = responseJson.slice(jsonStart);

        const result = JSON.parse(jsonStr);
        const rawBytes = result.returns["0"].value;

        return rawBytes;
    } catch (error) {
        console.error("Error running MockCLFReport script:", error);
        throw error;
    }
}

export { getOperatorRegistrationCLFResponse };
