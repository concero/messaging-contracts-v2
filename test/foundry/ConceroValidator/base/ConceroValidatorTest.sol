// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Namespaces as ValidatorNamespaces} from "contracts/ConceroValidator/libraries/Storage.sol";
import {ConceroValidator} from "contracts/ConceroValidator/ConceroValidator.sol";

import {ConceroTest} from "../../utils/ConceroTest.sol";
import {DeployConceroValidator} from "../../scripts/deploy/DeployConceroValidator.s.sol";

import {MockCLFRouter} from "contracts/mocks/MockCLFRouter.sol";

abstract contract ConceroValidatorTest is DeployConceroValidator, ConceroTest {
    function setUp() public virtual override(DeployConceroValidator, ConceroTest) {
        super.setUp();

        conceroValidator = ConceroValidator(payable(deploy()));

        MockCLFRouter(clfRouter).setConsumer(address(conceroValidator));

        _setPriceFeeds();
        _setGasFeeConfig();
    }

    function _setGasFeeConfig() internal {
        vm.startPrank(deployer);
        conceroValidator.setGasFeeConfig(
            VRF_MSG_REPORT_REQUEST_GAS_OVERHEAD,
            CLF_GAS_PRICE_OVER_ESTIMATION_BPS,
            CLF_CALLBACK_GAS_OVERHEAD,
            CLF_CALLBACK_GAS_LIMIT
        );
        vm.stopPrank();
    }

    function _deposit(uint256 amount) internal {
        vm.deal(relayer, amount);
        vm.prank(relayer);
        conceroValidator.deposit{value: amount}();
    }
}
