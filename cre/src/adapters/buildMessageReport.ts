import { main as buildClfMessageReport } from "../../../clf/src/messageReport/index";

export function buildMessageReportBytes(): Uint8Array {
  const bytes = buildClfMessageReport();
  if (!(bytes instanceof Uint8Array)) {
    throw new Error("CLF messageReport main() must return Uint8Array");
  }
  return bytes;
}
