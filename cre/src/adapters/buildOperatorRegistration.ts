import { main as buildClfOperatorRegistration } from "../../../clf/src/operatorRegistration/index";

export function buildOperatorRegistrationBytes(): Uint8Array {
  const bytes = buildClfOperatorRegistration();
  if (!(bytes instanceof Uint8Array)) {
    throw new Error("CLF operatorRegistration main() must return Uint8Array");
  }
  return bytes;
}
