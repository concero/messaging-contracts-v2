import {cre, type HTTPPayload, Runner, type Runtime} from "@chainlink/cre-sdk";

import {GlobalContext} from "./types";
import {pipeline} from "./pipeline";


const onHttpTrigger = async (runtime: Runtime<GlobalContext>, payload: HTTPPayload) => {
    return pipeline(runtime, payload);
}

const initWorkflow = (ctx: GlobalContext) => {
    const httpTrigger = new cre.capabilities.HTTPCapability().trigger({})

    return [cre.handler(httpTrigger, onHttpTrigger)]
}

export async function main() {
    const runner = await Runner.newRunner<GlobalContext>()

    await runner.run(initWorkflow)
}

main()