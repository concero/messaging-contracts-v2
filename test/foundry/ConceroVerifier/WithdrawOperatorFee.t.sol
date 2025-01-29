// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Vm} from "forge-std/src/Vm.sol";
import {console} from "forge-std/src/Console.sol";

import {ConceroVerifier} from "../../../contracts/ConceroVerifier/ConceroVerifier.sol";
import {VerifierSlots} from "../../../contracts/ConceroVerifier/libraries/StorageSlots.sol";
import {DeployConceroVerifier} from "../scripts/DeployConceroVerifier.s.sol";

import {Constants} from "../../../contracts/common/Constants.sol";
import {Utils as CommonUtils} from "../../../contracts/common/libraries/Utils.sol";
import {CommonErrors} from "../../../contracts/common/CommonErrors.sol";
import {Namespaces} from "../../../contracts/ConceroVerifier/libraries/Storage.sol";
import {Types} from "../../../contracts/ConceroVerifier/libraries/Types.sol";
import {Errors} from "../../../contracts/ConceroVerifier/libraries/Errors.sol";
import {TransparentUpgradeableProxy} from "../../../contracts/Proxy/TransparentUpgradeableProxy.sol";
import {ConceroVerifierTest} from "../utils/ConceroVerifierTest.sol";
import {OperatorSlots, PriceFeedSlots} from "../../../contracts/ConceroVerifier/libraries/StorageSlots.sol";
import {ConceroVerifierDeploymentVariables} from "../scripts/ConceroVerifierDeploymentVariables.sol";

contract WithdrawOperatorFee is ConceroVerifierTest, ConceroVerifierDeploymentVariables {
    uint256 public constant NATIVE_USD_RATE = 2000e18; // Assuming 1 ETH = $2000
    uint256 public constant LAST_GAS_PRICE = 1_000_000 wei;
    uint256 public constant OPERATOR_FEE_AMOUNT = 1 ether;

    function setUp() public override {
        super.setUp();
        deployScript = new DeployConceroVerifier();
        address deployedProxy = deployScript.run();

        conceroVerifierProxy = TransparentUpgradeableProxy(payable(deployedProxy));
        conceroVerifier = ConceroVerifier(payable(deployScript.getProxy()));

        vm.deal(operator, 100 ether);

        bytes32 operatorKey = bytes32(uint256(uint160(operator)));

        vm.prank(deployer);
        conceroVerifier.setStorage(Namespaces.OPERATOR, OperatorSlots.isAllowed, operatorKey, 1);

        _setPriceFeeds();
    }

    function _setPriceFeeds() internal {
        vm.startPrank(deployer);

        conceroVerifier.setStorage(
            Namespaces.PRICEFEED,
            PriceFeedSlots.nativeUsdRate,
            bytes32(0),
            NATIVE_USD_RATE
        );

        conceroVerifier.setStorage(
            Namespaces.PRICEFEED,
            PriceFeedSlots.lastGasPrices,
            bytes32(uint256(chainSelector)),
            LAST_GAS_PRICE
        );

        conceroVerifier.setStorage(
            Namespaces.PRICEFEED,
            PriceFeedSlots.nativeNativeRates,
            bytes32(uint256(chainSelector)),
            1e18
        );

        vm.stopPrank();
    }

    function _setOperatorFeesEarned() internal {
        vm.startPrank(deployer);

        conceroVerifier.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(operator))),
            OPERATOR_FEE_AMOUNT
        );

        conceroVerifier.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0),
            OPERATOR_FEE_AMOUNT
        );

        vm.stopPrank();
    }

    function test_withdrawOperatorFee() public {
        _setOperatorFeesEarned();

        uint256 initialBalance = operator.balance;
        vm.deal(address(conceroVerifier), OPERATOR_FEE_AMOUNT);

        vm.prank(operator);
        conceroVerifier.withdrawOperatorFee(OPERATOR_FEE_AMOUNT);

        assertEq(conceroVerifier.getOperatorFeesEarned(operator), 0, "Fees not cleared");
        assertEq(operator.balance, initialBalance + OPERATOR_FEE_AMOUNT, "Balance mismatch");
    }

    function test_withdrawOperatorFee_WhenAmountZero_Reverts() public {
        vm.prank(operator);
        vm.expectRevert(CommonErrors.InvalidAmount.selector);
        conceroVerifier.withdrawOperatorFee(0);
    }

    function test_withdrawOperatorFee_WhenInsufficientBalance_Reverts() public {
        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.InsufficientFee.selector, OPERATOR_FEE_AMOUNT, 0)
        );
        conceroVerifier.withdrawOperatorFee(OPERATOR_FEE_AMOUNT);
    }
}
