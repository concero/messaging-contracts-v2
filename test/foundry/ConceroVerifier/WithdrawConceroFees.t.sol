// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Errors} from "../../../contracts/ConceroVerifier/libraries/Errors.sol";
import {Namespaces} from "../../../contracts/ConceroVerifier/libraries/Storage.sol";
import {OperatorSlots} from "../../../contracts/ConceroVerifier/libraries/StorageSlots.sol";
import {CommonErrors} from "../../../contracts/common/CommonErrors.sol";
import {ConceroTest, ConceroBaseScript} from "../utils/ConceroTest.sol";
import {ConceroVerifierTest} from "../utils/ConceroVerifierTest.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {CommonBase} from "forge-std/src/Base.sol";
import {StdAssertions} from "forge-std/src/StdAssertions.sol";
import {StdChains} from "forge-std/src/StdChains.sol";
import {StdCheats, StdCheatsSafe} from "forge-std/src/StdCheats.sol";
import {StdUtils} from "forge-std/src/StdUtils.sol";

contract WithdrawConceroFees is ConceroVerifierTest {
    using SafeERC20 for IERC20;

    uint256 public constant TOTAL_NATIVE_BALANCE = 10 ether;
    uint256 public constant TOTAL_USDC_BALANCE = 10000e6;

    uint256 public constant TOTAL_OPERATOR_FEES_NATIVE = 2 ether;
    uint256 public constant TOTAL_OPERATOR_DEPOSITS_NATIVE = 3 ether;

    uint256 public constant OPERATOR_FEES_NATIVE = 1 ether;
    uint256 public constant OPERATOR_DEPOSIT_NATIVE = 1.5 ether;

    function setUp() public override {
        super.setUp();
        usdc = deployScript.USDC();

        vm.deal(address(conceroVerifier), TOTAL_NATIVE_BALANCE);
        deal(usdc, address(conceroVerifier), TOTAL_USDC_BALANCE);
        _setOperatorBalances();
    }

    function _setOperatorBalances() internal {
        vm.startPrank(deployer);

        conceroVerifier.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0),
            TOTAL_OPERATOR_FEES_NATIVE
        );

        conceroVerifier.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalDepositsNative,
            bytes32(0),
            TOTAL_OPERATOR_DEPOSITS_NATIVE
        );

        conceroVerifier.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.feesEarnedNative,
            bytes32(uint256(uint160(operator))),
            OPERATOR_FEES_NATIVE
        );

        conceroVerifier.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.depositsNative,
            bytes32(uint256(uint160(operator))),
            OPERATOR_DEPOSIT_NATIVE
        );

        vm.stopPrank();
    }

    function test_withdrawConceroFees() public {
        uint256 withdrawableBalance = TOTAL_NATIVE_BALANCE -
            (TOTAL_OPERATOR_FEES_NATIVE + TOTAL_OPERATOR_DEPOSITS_NATIVE);

        vm.startPrank(deployer);

        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = withdrawableBalance;

        uint256 ownerBalanceBefore = deployer.balance;
        conceroVerifier.withdrawConceroFees(tokens, amounts);

        assertEq(
            deployer.balance - ownerBalanceBefore,
            withdrawableBalance,
            "Incorrect withdrawable balance"
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
        conceroVerifier.withdrawConceroFees(tokens, amounts);

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

        conceroVerifier.withdrawConceroFees(tokens, amounts);

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
        conceroVerifier.withdrawConceroFees(tokens, amounts);
        vm.stopPrank();
    }

    function test_withdrawConceroFees_WhenArraysEmpty_Reverts() public {
        vm.startPrank(deployer);

        address[] memory tokens = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        vm.expectRevert(CommonErrors.LengthMismatch.selector);
        conceroVerifier.withdrawConceroFees(tokens, amounts);
        vm.stopPrank();
    }

    function test_withdrawConceroFees_WhenNotOwner_Reverts() public {
        vm.startPrank(address(0x1234));

        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;

        vm.expectRevert(CommonErrors.NotOwner.selector);
        conceroVerifier.withdrawConceroFees(tokens, amounts);
        vm.stopPrank();
    }

    function test_withdrawConceroFees_WhenInsufficientFee_Reverts() public {
        vm.startPrank(deployer);

        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = TOTAL_NATIVE_BALANCE + 1;

        uint256 availableFees = TOTAL_NATIVE_BALANCE -
            (TOTAL_OPERATOR_FEES_NATIVE + TOTAL_OPERATOR_DEPOSITS_NATIVE);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InsufficientFee.selector, amounts[0], availableFees)
        );
        conceroVerifier.withdrawConceroFees(tokens, amounts);
        vm.stopPrank();
    }

    function test_withdrawConceroFees_WhenZeroAmount_Reverts() public {
        vm.startPrank(deployer);

        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;

        vm.expectRevert(CommonErrors.InvalidAmount.selector);
        conceroVerifier.withdrawConceroFees(tokens, amounts);
        vm.stopPrank();
    }
}
