// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {console} from "forge-std/src/console.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {CommonErrors} from "contracts/common/CommonErrors.sol";

import {Namespaces} from "contracts/ConceroRouter/libraries/Storage.sol";
import {OperatorSlots} from "contracts/ConceroRouter/libraries/StorageSlots.sol";

import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";

contract WithdrawConceroFees is ConceroRouterTest {
    using SafeERC20 for IERC20;

    uint256 public constant TOTAL_NATIVE_BALANCE = 10 ether;
    uint256 public constant TOTAL_USDC_BALANCE = 10000e6;

    function setUp() public override {
        super.setUp();

        vm.deal(address(conceroRouter), TOTAL_NATIVE_BALANCE);
        deal(usdc, address(conceroRouter), TOTAL_USDC_BALANCE);
        _setOperatorBalances();
    }

    function _setOperatorBalances() internal {
        vm.startPrank(deployer);

        // Set total operator fees
        conceroRouter.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0),
            OPERATOR_FEES_NATIVE
        );

        // Set individual operator fees
        conceroRouter.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(operator))),
            OPERATOR_FEES_NATIVE
        );

        vm.stopPrank();
    }

    function test_withdrawConceroFees() public {
        uint256 withdrawableBalance = TOTAL_NATIVE_BALANCE - OPERATOR_FEES_NATIVE;

        vm.startPrank(deployer);

        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = withdrawableBalance;

        uint256 ownerBalanceBefore = deployer.balance;
        conceroRouter.withdrawConceroFees(tokens, amounts);

        assertEq(
            deployer.balance - ownerBalanceBefore,
            withdrawableBalance,
            "Incorrect withdrawable balance"
        );
        vm.stopPrank();
    }

    function test_withdrawConceroFees_VerifyOperatorFees() public {
        vm.startPrank(deployer);

        uint256 operatorFees = conceroRouter.getStorage(
            Namespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(operator)))
        );

        assertEq(operatorFees, OPERATOR_FEES_NATIVE, "Incorrect operator fees");
        vm.stopPrank();
    }

    function test_withdrawConceroFees_Native() public {
        vm.startPrank(deployer);

        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;

        uint256 ownerBalanceBefore = deployer.balance;
        conceroRouter.withdrawConceroFees(tokens, amounts);

        assertEq(
            deployer.balance - ownerBalanceBefore,
            1 ether,
            "Incorrect native token withdrawal amount"
        );
        vm.stopPrank();
    }

    function test_withdrawConceroFees_USDC() public {
        vm.startPrank(deployer);

        address[] memory tokens = new address[](1);
        tokens[0] = usdc;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1000e6;

        uint256 ownerBalanceBefore = IERC20(usdc).balanceOf(deployer);
        conceroRouter.withdrawConceroFees(tokens, amounts);

        assertEq(
            IERC20(usdc).balanceOf(deployer) - ownerBalanceBefore,
            1000e6,
            "Incorrect USDC withdrawal amount"
        );
        vm.stopPrank();
    }

    function test_withdrawConceroFees_multipleTokens() public {
        vm.startPrank(deployer);

        address[] memory tokens = new address[](2);
        tokens[0] = address(0);
        tokens[1] = usdc;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1 ether;
        amounts[1] = 1000e6;

        uint256 ownerNativeBalanceBefore = deployer.balance;
        uint256 ownerUsdcBalanceBefore = IERC20(usdc).balanceOf(deployer);

        conceroRouter.withdrawConceroFees(tokens, amounts);

        assertEq(
            deployer.balance - ownerNativeBalanceBefore,
            1 ether,
            "Incorrect native token withdrawal amount"
        );
        assertEq(
            IERC20(usdc).balanceOf(deployer) - ownerUsdcBalanceBefore,
            1000e6,
            "Incorrect USDC withdrawal amount"
        );
        vm.stopPrank();
    }

    function test_withdrawConceroFees_WhenArrayLengthsMismatch_Reverts() public {
        vm.startPrank(deployer);

        address[] memory tokens = new address[](2);
        tokens[0] = address(0);
        tokens[1] = usdc;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;

        vm.expectRevert(CommonErrors.LengthMismatch.selector);
        conceroRouter.withdrawConceroFees(tokens, amounts);
        vm.stopPrank();
    }

    function test_withdrawConceroFees_WhenArraysEmpty_Reverts() public {
        vm.startPrank(deployer);

        address[] memory tokens = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        vm.expectRevert(CommonErrors.LengthMismatch.selector);
        conceroRouter.withdrawConceroFees(tokens, amounts);
        vm.stopPrank();
    }

    function test_withdrawConceroFees_WhenNotOwner_Reverts() public {
        vm.startPrank(address(0x1234));

        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;

        vm.expectRevert(CommonErrors.Unauthorized.selector);
        conceroRouter.withdrawConceroFees(tokens, amounts);
        vm.stopPrank();
    }

    function test_withdrawConceroFees_WhenInsufficientFee_Reverts() public {
        vm.startPrank(deployer);

        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = TOTAL_NATIVE_BALANCE + 1;

        uint256 availableFees = TOTAL_NATIVE_BALANCE - OPERATOR_FEES_NATIVE;

        vm.expectRevert(
            abi.encodeWithSelector(CommonErrors.InsufficientFee.selector, amounts[0], availableFees)
        );
        conceroRouter.withdrawConceroFees(tokens, amounts);
        vm.stopPrank();
    }

    function test_withdrawConceroFees_WhenZeroAmount_Reverts() public {
        vm.startPrank(deployer);

        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;

        vm.expectRevert(CommonErrors.InvalidAmount.selector);
        conceroRouter.withdrawConceroFees(tokens, amounts);
        vm.stopPrank();
    }
}
