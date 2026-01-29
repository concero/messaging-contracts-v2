import { getEnvVar } from "./getEnvVar";

export const getTrezorDeployEnabled = () => getEnvVar("TREZOR_DEPLOY_ENABLED") === "true";
