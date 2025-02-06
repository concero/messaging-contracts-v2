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

contract WithdrawOperatorDeposit is ConceroVerifierTest, ConceroVerifierDeploymentVariables {
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

        console.logBytes32(Namespaces.PRICEFEED);
        vm.stopPrank();
    }

    function test_OperatorDeposit() public {
        uint256 minimumDeposit = conceroVerifier.getCLFDeposit();

        vm.prank(operator);
        conceroVerifier.operatorDeposit{value: minimumDeposit}(operator);

        assertEq(
            conceroVerifier.getOperatorDeposit(operator),
            minimumDeposit,
            "Operator deposit amount mismatch"
        );
    }

    function test_MultipleDeposits() public {
        uint256 minimumDeposit = conceroVerifier.getCLFDeposit();

        vm.startPrank(operator);
        conceroVerifier.operatorDeposit{value: minimumDeposit}(operator);
        conceroVerifier.operatorDeposit{value: minimumDeposit}(operator);

        assertEq(
            conceroVerifier.getOperatorDeposit(operator),
            minimumDeposit * 2,
            "Multiple deposits should accumulate correctly"
        );
        vm.stopPrank();
    }

    function test_WithdrawOperatorDeposit() public {
        uint256 depositAmount = conceroVerifier.getCLFDeposit();
        uint256 withdrawAmount = depositAmount;

        vm.prank(operator);
        conceroVerifier.operatorDeposit{value: depositAmount}(operator);

        uint256 preWithdrawBalance = operator.balance;

        vm.prank(operator);
        bool success = conceroVerifier.withdrawOperatorDeposit(withdrawAmount);

        assertTrue(success, "Withdrawal should succeed");

        assertEq(
            conceroVerifier.getOperatorDeposit(operator),
            depositAmount - withdrawAmount,
            "Remaining deposit amount mismatch"
        );

        assertEq(operator.balance, preWithdrawBalance + withdrawAmount, "Balance change mismatch");
    }

    function test_withdrawOperatorDeposit_WhenAmountZero_Reverts() public {
        vm.prank(operator);
        vm.expectRevert(CommonErrors.InvalidAmount.selector);
        conceroVerifier.withdrawOperatorDeposit(0);
    }

    function test_withdrawOperatorDeposit_WhenAmountExceedsDeposit_Reverts() public {
        uint256 minimumDeposit = conceroVerifier.getCLFDeposit();
        uint256 depositAmount = minimumDeposit;
        uint256 withdrawAmount = depositAmount + 1 ether;

        vm.prank(operator);
        conceroVerifier.operatorDeposit{value: depositAmount}(operator);

        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InsufficientOperatorDeposit.selector,
                depositAmount,
                withdrawAmount
            )
        );
        conceroVerifier.withdrawOperatorDeposit(withdrawAmount);
    }

    function test_withdrawOperatorDeposit_WhenAmountBelowMinimum_Reverts() public {
        uint256 minimumDeposit = conceroVerifier.getCLFDeposit();
        uint256 depositAmount = minimumDeposit;
        uint256 withdrawAmount = depositAmount + 1;

        vm.prank(operator);
        conceroVerifier.operatorDeposit{value: depositAmount}(operator);

        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InsufficientOperatorDeposit.selector,
                depositAmount,
                withdrawAmount
            )
        );
        conceroVerifier.withdrawOperatorDeposit(withdrawAmount);
    }
}
