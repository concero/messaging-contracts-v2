export const conceroMessageAbi = [
    {
        components: [
            {
                internalType: "uint64",
                name: "srcChainSelector",
                type: "uint64",
            },
            {
                internalType: "uint64",
                name: "dstChainSelector",
                type: "uint64",
            },
            {
                internalType: "address",
                name: "receiver",
                type: "address",
            },
            {
                internalType: "address",
                name: "sender",
                type: "address",
            },
            {
                components: [
                    {
                        internalType: "address",
                        name: "token",
                        type: "address",
                    },
                    {
                        internalType: "uint256",
                        name: "amount",
                        type: "uint256",
                    },
                ],
                internalType: "struct IMessage.TokenAmount[]",
                name: "tokenAmounts",
                type: "tuple[]",
            },
            {
                internalType: "enum IMessage.Relayer[]",
                name: "relayers",
                type: "uint8[]",
            },
            {
                internalType: "bytes",
                name: "data",
                type: "bytes",
            },
            {
                internalType: "bytes",
                name: "extraArgs",
                type: "bytes",
            },
        ],
        name: "Message",
        type: "tuple",
    },
];
