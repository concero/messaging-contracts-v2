// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {IRelayer} from "contracts/interfaces/IRelayer.sol";
import {ConceroRouter} from "contracts/ConceroRouter/ConceroRouter.sol";
import {MockConceroRelayerLib} from "../mocks/MockConceroRelayerLib.sol";
import {MockConceroValidatorLib} from "../mocks/MockConceroValidatorLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MockPriceFeed} from "../mocks/MockPriceFeed.sol";
import {ConceroRouterHarness} from "../harnesses/ConceroRouterHarness.sol";
import {ValidatorCodec} from "contracts/common/libraries/ValidatorCodec.sol";

contract FeeCalculation is ConceroRouterTest {
    uint256 internal VALIDATOR_FEE = 0.01 ether;
    uint256 internal RELAYER_FEE = 0.001 ether;

    function test_ChargeFeeCorrectly() public {
        uint256 routerBalanceBefore = address(s_conceroRouter).balance;

        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();
        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);

        vm.prank(s_user);
        s_conceroRouter.conceroSend{value: messageFee}(messageRequest);

        uint256 routerBalanceAfter = address(s_conceroRouter).balance;
        uint256 relayerFeeEarned = s_conceroRouter.getRelayerFeeEarned(
            s_relayerLib,
            messageRequest.feeToken
        );

        assertEq(routerBalanceAfter - routerBalanceBefore, messageFee);
        assertEq(relayerFeeEarned, messageFee);
    }

    function test_chargeFeeInErc20() public {
        vm.startPrank(s_deployer);
        s_conceroRouter = new ConceroRouterHarness(SRC_CHAIN_SELECTOR);
        s_conceroRouter.initialize();

        s_dstConceroRouter = new ConceroRouterHarness(DST_CHAIN_SELECTOR);
        s_dstConceroRouter.initialize();

        deal(address(s_usdc), s_user, 100 ether);

        uint256 routerBalanceBefore = IERC20(s_usdc).balanceOf(address(s_conceroRouter));

        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest(address(s_usdc));

        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);

        vm.startPrank(s_user);
        IERC20(s_usdc).approve(address(s_conceroRouter), messageFee);
        s_conceroRouter.conceroSend{value: messageFee}(messageRequest);
        vm.stopPrank();

        uint256 routerBalanceAfter = IERC20(s_usdc).balanceOf(address(s_conceroRouter));
        uint256 relayerFeeEarned = s_conceroRouter.getRelayerFeeEarned(
            s_relayerLib,
            messageRequest.feeToken
        );

        assertEq(routerBalanceAfter - routerBalanceBefore, messageFee);
        assertEq(relayerFeeEarned, messageFee);
    }

    /* getMessageFee */

    function test_getMessageFee_CalculatesCorrectly() public view {
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();

        bytes[] memory validatorConfigs = new bytes[](1);
        validatorConfigs[0] = ValidatorCodec.encodeEvmConfig(10_000);

        uint256 relayerFee = MockConceroRelayerLib(payable(s_relayerLib)).getFee(
            messageRequest,
            validatorConfigs
        );
        uint256 validatorFee = MockConceroValidatorLib(s_validatorLib).getFee(messageRequest);

        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);

        uint256 totalFee = relayerFee + validatorFee;
        assertEq(messageFee, totalFee);
    }

    /* conceroSend */

    function test_conceroSend_EmitsConceroMessageFeePaid() public {
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();

        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);
        uint256 relayerFee = messageFee - VALIDATOR_FEE;

        uint256[] memory validatorsFee = new uint256[](1);
        validatorsFee[0] = VALIDATOR_FEE;

        IConceroRouter.Fee memory fee = IConceroRouter.Fee({
            relayer: relayerFee,
            validatorsFee: validatorsFee,
            token: messageRequest.feeToken
        });

        vm.expectEmit(false, false, false, true);
        emit IConceroRouter.ConceroMessageFeePaid(bytes32(0), fee);

        vm.prank(s_user);
        s_conceroRouter.conceroSend{value: messageFee}(messageRequest);
    }

    function test_conceroSend_RevertsIfInsufficientFee() public {
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();
        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);

        vm.expectRevert(
            abi.encodeWithSelector(
                IConceroRouter.InsufficientFee.selector,
                messageFee - 1,
                messageFee
            )
        );
        vm.prank(s_user);
        s_conceroRouter.conceroSend{value: messageFee - 1}(messageRequest);
    }

    /* withdrawRelayerFee */

    function test_withdrawRelayerFee_Success() public {
        _conceroSend();

        uint256 relayerBalanceBefore = address(s_relayerLib).balance;

        address[] memory tokens = new address[](1);

        vm.prank(address(s_relayerLib));
        s_conceroRouter.withdrawRelayerFee(tokens);

        assertEq(address(s_relayerLib).balance - relayerBalanceBefore, RELAYER_FEE + VALIDATOR_FEE);
    }

    function test_withdrawRelayerFee_EmitsRelayerFeeWithdrawn() public {
        _conceroSend();

        uint256 relayerFeeEarned = s_conceroRouter.getRelayerFeeEarned(s_relayerLib, address(0));

        address[] memory tokens = new address[](1);

        vm.expectEmit(true, true, false, true);
        emit IRelayer.RelayerFeeWithdrawn(s_relayerLib, address(0), relayerFeeEarned);

        vm.prank(address(s_relayerLib));
        s_conceroRouter.withdrawRelayerFee(tokens);
    }
}
