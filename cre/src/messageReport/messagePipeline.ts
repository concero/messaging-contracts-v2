import { HexString } from "ethers/lib.commonjs/utils/data";
import { decodeAbiParameters, type Hash, type Address, type Hex, keccak256, isAddress, hexToBytes, encodeAbiParameters, pad } from "viem";

import { CustomError, ErrorTypes } from "../error";
import { EvmSrcChainDataParams, NonIndexedConceroMessageParams, messageReportResultParams } from "../constants";
import { Log } from "../types";
import { DecodedArgs, EvmSrcChainData, MessageReportResult } from "./types";
import { hexStringToUint8Array } from "../encoders";


export class MessagePipeline {
    static decodeArgs(bytesArgs: string[]): MessagePipeline.DecodeArgs.Result {
        if (bytesArgs.length < 6) {
            throw new CustomError(ErrorTypes.Type.INVALID_BYTES_ARGS_LENGTH);
        }

        const [, hexSrcChainSelector, messageId, messageHashSum, srcChainData, operatorAddress] = bytesArgs;
        const srcChainSelector = Number(hexSrcChainSelector);

        const decodedArgs = {
            srcChainSelector,
            messageId,
            messageHashSum,
            srcChainData: MessagePipeline.decodeEvmSrcChainData(srcChainData),
            operatorAddress,
        };

        MessagePipeline.validateDecodedArgs(decodedArgs);
        return decodedArgs;
    }
    static validateOperatorAddress(address: string): void {
        if (!isAddress(address)) {
            throw new CustomError(ErrorTypes.Type.INVALID_OPERATOR_ADDRESS);
        }
    }
    static validateMessageFields(args: MessagePipeline.DecodeArgs.Result): void {
        const { messageId, messageHashSum, srcChainData } = args;

        if (!messageId || messageId.length === 0) {
            throw new CustomError(ErrorTypes.Type.INVALID_MESSAGE_ID);
        }

        if (!messageHashSum || messageHashSum.length === 0) {
            throw new CustomError(ErrorTypes.Type.INVALID_HASH_SUM);
        }

        if (!srcChainData || srcChainData.length === 0) {
            throw new CustomError(ErrorTypes.Type.INVALID_CHAIN_DATA);
        }
    }
    static validateDecodedArgs(args: DecodedArgs): void {
        MessagePipeline.validateOperatorAddress(args.operatorAddress);
        MessagePipeline.validateMessageFields(args);
    }

    static decodeMessageLog(log: Log): MessagePipeline.DecodeLog.Result {
        try {
            const [version, shouldFinaliseSrc, dstChainSelector, dstChainData, sender, message] = decodeAbiParameters(
                NonIndexedConceroMessageParams,
                log.data,
            );

            return {
                version,
                shouldFinaliseSrc,
                dstChainSelector,
                dstChainData,
                sender,
                message,
            };
        } catch (error) {
            throw new CustomError(ErrorTypes.Type.INVALID_DATA);
        }
    }
    static decodeEvmSrcChainData(encodedData: string): MessagePipeline.DecodeEvmSrcChainData.Result {
        try {
            const [sender, blockNumber] = decodeAbiParameters(EvmSrcChainDataParams, encodedData);

            return {
                sender,
                blockNumber: blockNumber.toString(),
            };
        } catch (error) {
            throw new CustomError(ErrorTypes.Type.INVALID_DATA);
        }
    }

    static decodeSrcChainData(srcChainSelector: bigint, srcChainData: string): EvmSrcChainData {
        const srcChainDataBytes = hexToBytes(srcChainData);

        return decodeAbiParameters(
            [
                {
                    type: "tuple",
                    components: [
                        { name: "blockNumber", type: "uint256" },
                        { name: "sender", type: "address" },
                    ],
                },
            ],
            srcChainDataBytes,
        )[0];
    }

    static verifyMessageHash(message: HexString, expectedHashSum: HexString): void {
        if (keccak256(message as Hex).toLowerCase() !== expectedHashSum.toLowerCase()) {
            throw new CustomError(ErrorTypes.Type.INVALID_HASHSUM);
        }
    }

    static packResult(result: MessageReportResult): Uint8Array {
        const decodedDstChainData = decodeAbiParameters(
            [
                {
                    type: "tuple",
                    components: [
                        { type: "address", name: "receiver" },
                        { type: "uint256", name: "gasLimit" },
                    ],
                },
            ],
            hexToBytes(result.dstChainData),
        );

        const messagePayloadV1 = encodeAbiParameters(messageReportResultParams, [
            {
                messageId: result.messageId,
                messageHashSum: result.messageHashSum,
                messageSender: encodeAbiParameters([{ type: "address" }], [result.messageSender]),
                srcChainSelector: result.srcChainSelector,
                dstChainSelector: result.dstChainSelector,
                srcBlockNumber: result.srcBlockNumber,
                dstChainData: decodedDstChainData[0],
                allowedOperators: result.allowedOperators.map(op => pad(op)),
            },
        ]);

        const encodedResult = encodeAbiParameters(
            [
                {
                    type: "tuple",
                    components: [
                        { type: "uint8", name: "resultType" },
                        { type: "uint8", name: "payloadVersion" },
                        { type: "address", name: "requester" },
                    ],
                }, // ResultConfig
                { type: "bytes" }, // payload
            ],
            [
                {
                    resultType: result.resultType,
                    payloadVersion: result.payloadVersion,
                    requester: result.requester,
                },
                messagePayloadV1,
            ],
        );

        return hexStringToUint8Array(encodedResult);
    }

}

export namespace MessagePipeline {
    export namespace DecodeArgs {
        export type Result = {
            messageId: Hash;
            messageHashSum: Hash;
            srcChainSelector: Number;
            srcChainData: EvmSrcChainData;
            operatorAddress: Address;
        }
    }

    export namespace DecodeLog {
        export type Result = {
            version: HexString;
            shouldFinaliseSrc: HexString;
            dstChainSelector: HexString;
            dstChainData: HexString;
            sender: HexString;
            message: HexString;
        }
    }
    export namespace DecodeEvmSrcChainData {
        export type Result = {
            sender: Address;
            blockNumber: string;
        }
    }
}