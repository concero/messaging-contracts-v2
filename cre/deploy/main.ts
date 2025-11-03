import { cre, type HTTPPayload, Runner, type Runtime } from "@chainlink/cre-sdk";

import { pipeline } from "./pipeline";
import { GlobalContext } from "./types";


const onHttpTrigger = async (runtime: Runtime<GlobalContext>, payload: HTTPPayload) => {
    runtime.log(`HTTP trigger received: ${payload.input.length} bytes`)

    try {
        const result = await pipeline(runtime, payload)
        runtime.log(`HTTP trigger pipeline succeeded`)
        return result;
    } catch (e) {
        runtime.log(`HTTP trigger pipeline failed: ${e instanceof Error ? e.message : e?.toString()}`)
        return "0x000000000000000000000"
    }
}

async function main() {
    const runner = await Runner.newRunner<GlobalContext>()

    await runner.run((config: GlobalContext) => {
        const httpTrigger = new cre.capabilities.HTTPCapability().trigger(config)

        return [cre.handler(httpTrigger, onHttpTrigger)]
    })
}

main()
