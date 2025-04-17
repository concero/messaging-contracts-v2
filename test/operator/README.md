## Operator testing pipeline

1. in v2-contracts, run: `yarn run chain` (to start hardhat node)
2. in v2-contracts, run: `yarn run operator-setup` (to deploy contracts and set price feeds)
3. in v2-operators, run: `yarn ./src/relayer/a/index.ts` (to start relayer)
