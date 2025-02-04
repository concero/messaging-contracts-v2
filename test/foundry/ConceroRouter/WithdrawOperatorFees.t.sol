// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {console} from "forge-std/src/console.sol";

import {CommonErrors} from "../../../contracts/common/CommonErrors.sol";
import {ConceroRouterTest} from "../utils/ConceroRouterTest.sol";
import {Namespaces} from "../../../contracts/ConceroRouter/libraries/Storage.sol";
import {OperatorSlots} from "../../../contracts/ConceroRouter/libraries/StorageSlots.sol";

contract WithdrawOperatorFees is ConceroRouterTest {
    using SafeERC20 for IERC20;

    uint256 public constant OPERATOR_FEES_NATIVE = 1 ether;
    uint256 public constant TOTAL_FEES_NATIVE = 1 ether;

    function setUp() public override {
        super.setUp();
        _setOperatorFees();
        vm.deal(address(conceroRouter), OPERATOR_FEES_NATIVE);
    }

    function _setOperatorFees() internal {
        vm.startPrank(deployer);
        conceroRouter.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(operator))),
            OPERATOR_FEES_NATIVE
        );
        conceroRouter.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0),
            TOTAL_FEES_NATIVE
        );
        vm.stopPrank();
    }

    function test_WithdrawOperatorFees_Native() public {
        uint256 initialBalance = operator.balance;
        vm.prank(operator);
        conceroRouter.withdrawOperatorFee(OPERATOR_FEES_NATIVE);

        assertEq(
            operator.balance,
            initialBalance + OPERATOR_FEES_NATIVE,
            "Native balance mismatch"
        );

        uint256 remainingFees = conceroRouter.getStorage(
            Namespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(operator)))
        );
        assertEq(remainingFees, 0, "Fees earned not cleared");

        uint256 totalFees = conceroRouter.getStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0)
        );
        assertEq(totalFees, 0, "Total fees not decremented");
    }

    function test_WithdrawOperatorFees_WhenZeroAmount_Reverts() public {
        vm.prank(operator);
        vm.expectRevert(CommonErrors.InvalidAmount.selector);
        conceroRouter.withdrawOperatorFee(0);
    }

    function test_WithdrawOperatorFees_InsufficientFees_Reverts() public {
        uint256 excessAmount = OPERATOR_FEES_NATIVE + 1;
        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                CommonErrors.InsufficientFee.selector,
                excessAmount,
                OPERATOR_FEES_NATIVE
            )
        );
        conceroRouter.withdrawOperatorFee(excessAmount);
    }
}
