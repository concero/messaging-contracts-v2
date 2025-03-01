import { HexString } from "ethers/lib.commonjs/utils/data";
import { MASKS } from "../clf/src/common/bitMasks";
import { INTERNAL_MESSAGE_CONFIG_OFFSETS } from "../clf/src/messageReport/constants/internalMessageConfig";

export class ConceroMessageConfig {
    private config: bigint = BigInt(0);

    public setVersion(version: number) {
        this.config &= ~(MASKS.UINT8 << BigInt(INTERNAL_MESSAGE_CONFIG_OFFSETS.VERSION));
        this.config |= (BigInt(version) & MASKS.UINT8) << BigInt(INTERNAL_MESSAGE_CONFIG_OFFSETS.VERSION);
    }

    public setSrcChainSelector(srcChainSelector: bigint) {
        this.config &= ~(MASKS.UINT24 << BigInt(INTERNAL_MESSAGE_CONFIG_OFFSETS.SRC_CHAIN));
        this.config |= (srcChainSelector & MASKS.UINT24) << BigInt(INTERNAL_MESSAGE_CONFIG_OFFSETS.SRC_CHAIN);
    }

    public setDstChainSelector(dstChainSelector: bigint) {
        this.config &= ~(MASKS.UINT24 << BigInt(INTERNAL_MESSAGE_CONFIG_OFFSETS.DST_CHAIN));
        this.config |= (dstChainSelector & MASKS.UINT24) << BigInt(INTERNAL_MESSAGE_CONFIG_OFFSETS.DST_CHAIN);
    }

    public setMinSrcConfirmations(minSrcConfirmations: number) {
        this.config &= ~(MASKS.UINT16 << BigInt(INTERNAL_MESSAGE_CONFIG_OFFSETS.MIN_SRC_CONF));
        this.config |=
            (BigInt(minSrcConfirmations) & MASKS.UINT16) << BigInt(INTERNAL_MESSAGE_CONFIG_OFFSETS.MIN_SRC_CONF);
    }

    public setMinDstConfirmations(minDstConfirmations: number) {
        this.config &= ~(MASKS.UINT16 << BigInt(INTERNAL_MESSAGE_CONFIG_OFFSETS.MIN_DST_CONF));
        this.config |=
            (BigInt(minDstConfirmations) & MASKS.UINT16) << BigInt(INTERNAL_MESSAGE_CONFIG_OFFSETS.MIN_DST_CONF);
    }

    public setRelayerConfig(relayerConfig: number) {
        this.config &= ~(MASKS.UINT8 << BigInt(INTERNAL_MESSAGE_CONFIG_OFFSETS.RELAYER));
        this.config |= (BigInt(relayerConfig) & MASKS.UINT8) << BigInt(INTERNAL_MESSAGE_CONFIG_OFFSETS.RELAYER);
    }

    public setIsCallbackable(isCallbackable: boolean) {
        this.config &= ~(MASKS.BOOL << BigInt(INTERNAL_MESSAGE_CONFIG_OFFSETS.CALLBACKABLE));
        this.config |=
            (BigInt(isCallbackable ? 1 : 0) & MASKS.BOOL) << BigInt(INTERNAL_MESSAGE_CONFIG_OFFSETS.CALLBACKABLE);
    }

    get hexConfig(): HexString {
        return `0x${this.config.toString(16).padStart(32, "0")}` as HexString;
    }
}
