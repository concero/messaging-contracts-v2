import { execSync } from "child_process";

function getCLFReport(response: string) {
    try {
      const command = `make script "args=test/foundry/scripts/MockCLFReport/MessageReport.sol --sig 'getReport(bytes)' ${response} --json"`;
      const reportBytes = execSync(command).toString();
      const jsonStart = reportBytes.indexOf("{");
      const jsonStr = reportBytes.slice(jsonStart);
  
      const result = JSON.parse(jsonStr);
      
      // Foundry returns the result in the "returned" field which contains the encoded bytes for the entire struct
      return result.returned;

    } catch (error) {
      console.error("Error running getReport script:", error);
      throw error;
    }
  }

export { getCLFReport };
