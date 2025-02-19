import "./utils/configureOperatorEnv";
import { setupOperatorContracts } from "../../tasks/setupOperatorContracts";
import { ensureOperatorIsRegistered } from "@concero/v2-operators/src/relayer/a/contractCaller/ensureOperatorIsRegistered";
import { ensureDeposit } from "@concero/v2-operators/src/relayer/a/contractCaller/ensureDeposit";
import { setupEventListeners } from "@concero/v2-operators/src/relayer/a/eventListener/setupEventListeners";
import { checkGas } from "@concero/v2-operators/src/relayer/common/utils";
import { setupOperatorRegistrationEventListener } from "./utils/setupEventListeners";

//@notice Run 'bun chain' in a separate window, before running this script
async function operator() {
    void (await checkGas());
    void (await ensureDeposit());
    void (await ensureOperatorIsRegistered());
    void (await setupEventListeners());
}

async function testOperator() {
    await setupOperatorRegistrationEventListener();
    await setupOperatorContracts();
    await operator();
}

testOperator();

// export { testOperator };
