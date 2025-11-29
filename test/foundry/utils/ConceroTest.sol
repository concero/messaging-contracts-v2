// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Test} from "forge-std/src/Test.sol";
import {DeployConceroPriceFeed} from "../scripts/deploy/DeployConceroPriceFeed.s.sol";
import {ConceroPriceFeed} from "contracts/ConceroPriceFeed/ConceroPriceFeed.sol";
import {DeployMockERC20} from "../scripts/deploy/DeployMockERC20.s.sol";

abstract contract ConceroTest is Test {
    address public s_deployer = vm.envAddress("DEPLOYER_ADDRESS");
    address public s_proxyDeployer = vm.envAddress("PROXY_DEPLOYER_ADDRESS");

    address public s_operator = makeAddr("operator");
    address public s_user = makeAddr("user");
    address public s_relayer = makeAddr("relayer");
    address internal s_feedUpdater = makeAddr("feedUpdater");
    address public s_usdc = address(new DeployMockERC20().deployERC20("USD Coin", "USDC", 6));

    uint24 public constant SRC_CHAIN_SELECTOR = 1;
    uint24 public constant DST_CHAIN_SELECTOR = 8453;
    uint256 internal constant NATIVE_USD_RATE = 2000e18; // Assuming 1 ETH = $2000
    uint256 internal constant LAST_GAS_PRICE = 1e9;
    uint96 internal constant CONCERO_MESSAGE_FEE_IN_USD = 0.1e18; // $0.1
    uint64 internal constant MAX_CONCERO_MESSAGE_SIZE = 1000000; // 1 mb
    uint8 internal constant MAX_CONCERO_VALIDATORS_COUNT = 20;
    uint32 internal constant VALIDATION_GAS_LIMIT = 100_000;

    uint32 public constant SUBMIT_MSG_GAS_OVERHEAD = 150_000;
    uint32 public constant VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD = 330_000;
    uint32 public constant CLF_GAS_PRICE_OVER_ESTIMATION_BPS = 10_000;
    uint32 public constant CLF_CALLBACK_GAS_OVERHEAD = 240_000;

    ConceroPriceFeed internal s_conceroPriceFeed =
        ConceroPriceFeed(
            payable(new DeployConceroPriceFeed().deploy(SRC_CHAIN_SELECTOR, s_feedUpdater))
        );

    function _setPriceFeeds() internal {
        vm.startPrank(s_feedUpdater);

        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = SRC_CHAIN_SELECTOR;
        uint256[] memory gasPrices = new uint256[](1);
        gasPrices[0] = LAST_GAS_PRICE;

        s_conceroPriceFeed.setNativeUsdRate(NATIVE_USD_RATE);
        s_conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);

        vm.stopPrank();
    }

    receive() external payable {}
}
