// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Script} from "forge-std/src/Script.sol";

import {MessageConfigBitOffsets as offsets} from "contracts/common/CommonConstants.sol";
import {Types as VerifierTypes} from "contracts/ConceroVerifier/libraries/Types.sol";
import {DeployMockERC20} from "./deploy/DeployMockERC20.s.sol";
import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {Message as MessageLib} from "contracts/common/libraries/Message.sol";
import {ConceroTypes} from "contracts/ConceroClient/ConceroTypes.sol";
import {ConceroPriceFeed} from "contracts/ConceroPriceFeed/ConceroPriceFeed.sol";
import {console} from "forge-std/src/Console.sol";

abstract contract ConceroBaseScript is Script {
    ConceroPriceFeed internal conceroPriceFeed;

    address public immutable deployer;
    address public immutable proxyDeployer;
    uint64 immutable i_conceroVerifierSubscriptionId;

    address public constant operator = address(0x4242424242424242424242424242424242424242);
    address public constant user = address(0x0101010101010101010101010101010101010101);
    address constant CONCERO_VERIFIER_ADDRESS = address(0xa45F4A08eCE764a74cE20306d704e7CbD755D8a4);
    address constant feedUpdater = address(0xffff5136020B92553496625644479C7ce4614bE8);
    address public usdc;

    uint24 public constant SRC_CHAIN_SELECTOR = 1;
    uint24 public constant DST_CHAIN_SELECTOR = 8453;
    uint256 internal constant NATIVE_USD_RATE = 2000e18; // Assuming 1 ETH = $2000
    uint256 internal constant LAST_GAS_PRICE = 1e9;
    uint256 public constant OPERATOR_FEES_NATIVE = 2 ether;
    uint256 public constant OPERATOR_DEPOSIT_NATIVE = 3 ether;

    uint32 public constant SUBMIT_MSG_GAS_OVERHEAD = 150_000;
    uint32 public constant VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD = 330_000;
    uint32 public constant CLF_GAS_PRICE_OVER_ESTIMATION_BPS = 40_000;
    uint32 public constant CLF_CALLBACK_GAS_OVERHEAD = 240_000;
    uint32 public constant CLF_CALLBACK_GAS_LIMIT = 100_000;

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

    constructor() {
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        proxyDeployer = vm.envAddress("PROXY_DEPLOYER_ADDRESS");
        i_conceroVerifierSubscriptionId = uint64(vm.envUint("CLF_SUBID_LOCALHOST"));
    }

    function setUp() public virtual {
        usdc = address(new DeployMockERC20().deployERC20("USD Coin", "USDC", 6));
    }
}
