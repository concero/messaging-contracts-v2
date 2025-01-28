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

contract VerifierOperator is ConceroVerifierTest, ConceroVerifierDeploymentVariables {
    uint256 public constant NATIVE_USD_RATE = 2000e18; // Assuming 1 ETH = $2000
    uint256 public constant LAST_GAS_PRICE = 1_000_000 wei;

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
            1 ether
        );

        conceroVerifier.setStorage(
            Namespaces.OPERATOR,
            OperatorSlots.totalFeesEarnedNative,
            bytes32(0),
            1 ether
        );

        vm.stopPrank();
    }
    function test_GetCLFDeposit() public {
        // Calculate expected values
        uint256 expectedGasCost = clfCallbackGasLimit * LAST_GAS_PRICE;
        uint256 expectedPremiumFee = CommonUtils.convertUsdBpsToNative(
            clfPremiumFeeBpsUsd,
            NATIVE_USD_RATE
        );
        uint256 expectedDeposit = expectedGasCost + expectedPremiumFee;

        // Call the function and check the result
        uint256 actualDeposit = conceroVerifier.getCLFDeposit();
        assertEq(actualDeposit, expectedDeposit, "CLF deposit amount mismatch");
    }

    /* Deposits */
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

    function test_OperatorDepositBelowMinimum() public {
        uint256 minimumDeposit = conceroVerifier.getCLFDeposit();
        uint256 belowMinimum = minimumDeposit - 1;

        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InsufficientOperatorDeposit.selector,
                belowMinimum,
                minimumDeposit
            )
        );
        conceroVerifier.operatorDeposit{value: belowMinimum}(operator);
    }

    function test_RevertWhenZeroAddress() public {
        uint256 minimumDeposit = conceroVerifier.getCLFDeposit();

        vm.prank(operator);
        vm.expectRevert(CommonErrors.InvalidAddress.selector);
        conceroVerifier.operatorDeposit{value: minimumDeposit}(address(0));
    }

    function test_RevertWhenOperatorNotRegistered() public {
        address nonRegisteredOperator = address(0x2222);
        uint256 minimumDeposit = conceroVerifier.getCLFDeposit();

        vm.deal(nonRegisteredOperator, minimumDeposit);
        vm.prank(nonRegisteredOperator);

        vm.expectRevert(Errors.OperatorNotRegistered.selector);
        conceroVerifier.operatorDeposit{value: minimumDeposit}(nonRegisteredOperator);
    }

    function test_OperatorRegistration() public {
        uint256 minimumDeposit = conceroVerifier.getCLFDeposit();
        vm.prank(operator);
        conceroVerifier.operatorDeposit{value: minimumDeposit}(operator);

        Types.ChainType[] memory chainTypes = new Types.ChainType[](1);
        chainTypes[0] = Types.ChainType.EVM;

        Types.OperatorRegistrationAction[] memory actions = new Types.OperatorRegistrationAction[](
            1
        );
        actions[0] = Types.OperatorRegistrationAction.Register;

        bytes[] memory addresses = new bytes[](1);
        addresses[0] = abi.encode(operator);

        vm.prank(operator);
        vm.recordLogs();
        conceroVerifier.requestOperatorRegistration(chainTypes, actions, addresses);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestId;
        for (uint i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("RequestSent(bytes32)")) {
                requestId = bytes32(entries[i].topics[1]);
                break;
            }
        }

        uint256 storedStatus = conceroVerifier.getStorage(
            Namespaces.VERIFIER,
            VerifierSlots.pendingCLFRequests,
            requestId
        );

        assertEq(
            storedStatus,
            uint256(Types.CLFRequestStatus.Pending),
            "CLF request should be pending"
        );
    }

    function test_RestrictedOperatorFunctions() public {
        Types.MessageReportRequest memory request;

        vm.prank(nonOperator);
        vm.expectRevert(Errors.UnauthorizedOperator.selector);
        conceroVerifier.requestMessageReport(request);
    }

    function test_WithdrawOperatorFee() public {
        uint256 feeAmount = 1 ether;
        vm.deal(address(conceroVerifier), feeAmount);
        _setOperatorFeesEarned();

        uint256 initialBalance = operator.balance;

        vm.prank(operator);
        bool success = conceroVerifier.withdrawOperatorFee(feeAmount);

        assertTrue(success, "Withdrawal should succeed");
        assertEq(
            conceroVerifier.getOperatorFeesEarned(operator),
            0,
            "Fees should be zero after withdrawal"
        );
        assertEq(
            operator.balance,
            initialBalance + feeAmount,
            "Operator balance should increase by fee amount"
        );
    }

    function test_WithdrawOperatorFeeRevertZeroAmount() public {
        vm.prank(operator);
        vm.expectRevert(CommonErrors.InvalidAmount.selector);
        conceroVerifier.withdrawOperatorFee(0);
    }

    function test_WithdrawOperatorFeeRevertInsufficientBalance() public {
        uint256 feeAmount = 1 ether;
        uint256 currentFees = 0;

        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.InsufficientFee.selector, feeAmount, currentFees)
        );
        conceroVerifier.withdrawOperatorFee(feeAmount);
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

        // Should still have 2x minimum deposit remaining
        assertEq(
            conceroVerifier.getOperatorDeposit(operator),
            depositAmount - withdrawAmount,
            "Remaining deposit amount mismatch"
        );

        assertEq(operator.balance, preWithdrawBalance + withdrawAmount, "Balance change mismatch");
    }

    function test_WithdrawOperatorDepositRevertZeroAmount() public {
        vm.prank(operator);
        vm.expectRevert(CommonErrors.InvalidAmount.selector);
        conceroVerifier.withdrawOperatorDeposit(0);
    }

    function test_WithdrawOperatorDepositRevertInsufficientBalance() public {
        uint256 minimumDeposit = conceroVerifier.getCLFDeposit();
        uint256 depositAmount = minimumDeposit;
        uint256 withdrawAmount = depositAmount + 1 ether;

        vm.prank(operator);
        conceroVerifier.operatorDeposit{value: depositAmount}(operator);

        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InsufficientOperatorDeposit.selector,
                withdrawAmount,
                depositAmount
            )
        );
        conceroVerifier.withdrawOperatorDeposit(withdrawAmount);
    }

    function test_WithdrawOperatorDepositRevertBelowMinimum() public {
        uint256 minimumDeposit = conceroVerifier.getCLFDeposit();
        uint256 depositAmount = minimumDeposit;
        uint256 withdrawableAmount = depositAmount + 1;

        vm.prank(operator);
        conceroVerifier.operatorDeposit{value: depositAmount}(operator);

        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InsufficientOperatorDeposit.selector,
                withdrawableAmount,
                depositAmount
            )
        );
        conceroVerifier.withdrawOperatorDeposit(withdrawableAmount);
    }

    function test_WithdrawOperatorDepositRevertExcessAmount() public {
        uint256 minimumDeposit = conceroVerifier.getCLFDeposit();
        uint256 depositAmount = minimumDeposit;
        uint256 withdrawAmount = depositAmount + 1;

        vm.prank(operator);
        conceroVerifier.operatorDeposit{value: depositAmount}(operator);

        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InsufficientOperatorDeposit.selector,
                withdrawAmount,
                depositAmount
            )
        );
        conceroVerifier.withdrawOperatorDeposit(withdrawAmount);
    }
}
