## Operator testing pipeline

1. in v2-contracts, run: `yarn run chain` (to start hardhat node)
2. in v2-contracts, run: `yarn run operator-setup` (to deploy contracts and set price feeds)

## CLF finalize src test

1. Set environment variables:

```
NETWORK_MODE=localhost
CL_CCIP_CHAIN_SELECTOR_LOCALHOST=1
CONCERO_CLF_DEVELOPMENT=true
```

2. run: `yarn run chain` in separate terminal
3. run: `yarn run clf-finalize-src-test`

You will see the following output:

```bash
❌ FINALITY_NOT_REACHED: CLF returned a finalization error 71
12 blocks are mined ...
retrying requestMessageReportTxHash ... 
✅ FINALITY_REACHED: CLF returned a result without error
```

It means that test passed. First, CLF returned a finalization error, than we are waiting for 12 blocks (test amount of blocks) to be mined and then CLF returned a result without error for the same message.