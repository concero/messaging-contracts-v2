import { execSync } from "child_process";

async function getMockCLFReportBytes() {
    try {
        const output = execSync(
            `make script args="test/foundry/scripts/MockCLFReport.s.sol:MockCLFReport --json"`,
        ).toString();

        // Find the start of the JSON object
        const jsonStart = output.indexOf("{");
        const jsonStr = output.slice(jsonStart);

        const result = JSON.parse(jsonStr);
        const rawBytes = result.returns["0"].value;

        // console.log("Mock CLF Report Bytes:", rawBytes);
        return rawBytes;
    } catch (error) {
        console.error("Error running MockCLFReport script:", error);
        throw error;
    }
}

export { getMockCLFReportBytes };
