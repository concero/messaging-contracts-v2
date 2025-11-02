// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {DeployMockCLFRouter} from "../../scripts/deploy/DeployMockCLFRouter.s.sol";
import {ConceroTest} from "../../utils/ConceroTest.sol";
import {ConceroValidator} from "contracts/ConceroValidator/ConceroValidator.sol";
import {DeployConceroValidator} from "../../scripts/deploy/DeployConceroValidator.s.sol";
import {MockCLFRouter} from "contracts/mocks/MockCLFRouter.sol";
import {ConceroPriceFeed} from "contracts/ConceroPriceFeed/ConceroPriceFeed.sol";

abstract contract ConceroValidatorTest is ConceroTest {
    address public s_clfRouter = new DeployMockCLFRouter().run();
    bytes32 public s_clfDonId = vm.envBytes32("CLF_DONID_ARBITRUM");
    uint64 internal s_conceroValidatorSubscriptionId = uint64(vm.envUint("CLF_SUBID_LOCALHOST"));
    bytes32 public s_clfMessageReportRequestJsHashSum =
        vm.parseBytes32("0x66756e2d657468657265756d2d6d61696e6e65742d3100000000000000000000");
    uint16 public clfPremiumFeeBpsUsd = clfPremiumFeeBpsUsd = uint16(300);
    uint32 public clfCallbackGasLimit = uint32(100_000);
    uint32 public constant CLF_CALLBACK_GAS_LIMIT = 50_000;

    ConceroValidator internal s_conceroValidator =
        ConceroValidator(
            payable(
                (new DeployConceroValidator()).deploy(
                    s_clfMessageReportRequestJsHashSum,
                    SRC_CHAIN_SELECTOR,
                    s_clfRouter,
                    s_clfDonId,
                    s_conceroValidatorSubscriptionId,
                    address(new ConceroPriceFeed(SRC_CHAIN_SELECTOR, s_feedUpdater))
                )
            )
        );

    function setUp() public virtual {
        MockCLFRouter(s_clfRouter).setConsumer(address(s_conceroValidator));

        _setPriceFeeds();
        //        _setGasFeeConfig();
    }

    //    function _setGasFeeConfig() internal {
    //        vm.prank(s_deployer);
    //        s_conceroValidator.setGasFeeConfig(
    //            VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD,
    //            CLF_GAS_PRICE_OVER_ESTIMATION_BPS,
    //            CLF_CALLBACK_GAS_OVERHEAD,
    //            CLF_CALLBACK_GAS_LIMIT
    //        );
    //    }

    function _deposit(uint256 amount) internal {
        vm.deal(s_relayer, amount);
        vm.prank(s_relayer);
        (s_conceroValidator).deposit{value: amount}();
    }
}
