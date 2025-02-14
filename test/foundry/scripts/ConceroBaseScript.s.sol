pragma solidity 0.8.28;

import {Script} from "forge-std/src/Script.sol";
import {MessageConfigBitOffsets} from "contracts/common/libraries/Message.sol";
import {Types as VerifierTypes} from "contracts/ConceroVerifier/libraries/Types.sol";

abstract contract ConceroBaseScript is Script {
    address public immutable deployer;
    address public immutable proxyDeployer;

    address public constant operator = address(0x09354705);
    address public constant user = address(0x123);
    address public usdc;

    uint24 public constant SRC_CHAIN_SELECTOR = 8453;
    uint24 public constant DST_CHAIN_SELECTOR = 8453;

    address public constant MOCK_DON_SIGNER_ADDRESS_0 = 0x0004C7EdCF9283D3bc3C1309939b3E887bb9d98b;
    address public constant MOCK_DON_SIGNER_ADDRESS_1 = 0x000437D9bE1C11B748e8B4C349b818eE82682E9f;
    address public constant MOCK_DON_SIGNER_ADDRESS_2 = 0x000E512Da9116546247eE54Ffef6319E00331E1B;
    address public constant MOCK_DON_SIGNER_ADDRESS_3 = 0x0001E5818621C01908e989851ECB899Af3d57bDc;

    uint256 public constant MOCK_DON_SIGNER_PRIVATE_KEY_0 =
        0xc4811b8c87ec913b43de310600815ed870bc9984121627252d077c38ab76183d;
    uint256 public constant MOCK_DON_SIGNER_PRIVATE_KEY_1 =
        0xe55e1246012033fa1c89a1891a61bc4da0f1da259ec648a0fb6d3384f278f267;
    uint256 public constant MOCK_DON_SIGNER_PRIVATE_KEY_2 =
        0x36c5485ba3a564b7753ea1f3ba81d8b574b8b31e97abd9053c8eee938a8abce8;
    uint256 public constant MOCK_DON_SIGNER_PRIVATE_KEY_3 =
        0x31ec7a7d750fd8fdb2f80d6ba2a426afab415a2000092bcf529e6002697b2e31;

    uint256 internal constant NATIVE_USD_RATE = 2000e18; // Assuming 1 ETH = $2000
    uint256 internal constant LAST_GAS_PRICE = 1e9;
    uint256 public constant OPERATOR_FEES_NATIVE = 2 ether;
    uint256 public constant OPERATOR_DEPOSIT_NATIVE = 3 ether;

    uint256 internal constant CLIENT_MESSAGE_CONFIG =
        (uint256(DST_CHAIN_SELECTOR) << MessageConfigBitOffsets.OFFSET_DST_CHAIN) |
            (1 << MessageConfigBitOffsets.OFFSET_MIN_SRC_CONF) |
            (1 << MessageConfigBitOffsets.OFFSET_MIN_DST_CONF) |
            (0 << MessageConfigBitOffsets.OFFSET_RELAYER_CONF) |
            (0 << MessageConfigBitOffsets.OFFSET_CALLBACKABLE) |
            (uint256(VerifierTypes.FeeToken.native) << MessageConfigBitOffsets.OFFSET_FEE_TOKEN);

    uint256 internal constant INTERNAL_MESSAGE_CONFIG =
        (uint256(1) << MessageConfigBitOffsets.OFFSET_VERSION) | // version, assuming version is 1
            (uint256(SRC_CHAIN_SELECTOR) << MessageConfigBitOffsets.OFFSET_SRC_CHAIN) | // srcChainSelector
            (uint256(DST_CHAIN_SELECTOR) << MessageConfigBitOffsets.OFFSET_DST_CHAIN) | // dstChainSelector
            (uint256(1) << MessageConfigBitOffsets.OFFSET_MIN_SRC_CONF) | // minSrcConfirmations, assuming 1
            (uint256(1) << MessageConfigBitOffsets.OFFSET_MIN_DST_CONF) | // minDstConfirmations, assuming 1
            (uint256(0) << MessageConfigBitOffsets.OFFSET_RELAYER_CONF) | // relayerConfig, assuming 0
            (uint256(0) << MessageConfigBitOffsets.OFFSET_CALLBACKABLE); // isCallbackable, assuming false

    constructor() {
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        proxyDeployer = vm.envAddress("PROXY_DEPLOYER_ADDRESS");
    }
}
