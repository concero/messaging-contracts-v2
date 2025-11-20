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

contract FeeCalculation is ConceroRouterTest {
    uint256 internal VALIDATOR_FEE = 0.01 ether;
    uint256 internal RELAYER_FEE = 0.001 ether;

    function test_ChargeFeeCorrectly() public {
        uint256 routerBalanceBefore = address(s_conceroRouter).balance;

        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();
        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);
        uint256 conceroFee = s_conceroRouter.getConceroFee(messageRequest.feeToken);

        vm.prank(s_user);
        s_conceroRouter.conceroSend{value: messageFee}(messageRequest);

        uint256 routerBalanceAfter = address(s_conceroRouter).balance;
        uint256 relayerFeeEarned = s_conceroRouter.getRelayerFeeEarned(
            s_relayerLib,
            messageRequest.feeToken
        );
        uint256 totalRelayerFeeEarned = s_conceroRouter.exposed_getTotalRelayerFeeEarned(
            messageRequest.feeToken
        );

        assertEq(routerBalanceAfter - routerBalanceBefore, messageFee);
        assertEq(relayerFeeEarned, messageFee - conceroFee);
        assertEq(totalRelayerFeeEarned, messageFee - conceroFee);
    }

    function test_chargeFeeInErc20() public {
        vm.startPrank(s_deployer);
        s_conceroRouter = new ConceroRouterHarness(
            SRC_CHAIN_SELECTOR,
            address(new MockPriceFeed())
        );
        s_conceroRouter.setTokenConfig(address(s_usdc), true, uint8(6));
        s_conceroRouter.setMaxValidatorsCount(MAX_CONCERO_VALIDATORS_COUNT);
        vm.stopPrank();

        deal(address(s_usdc), s_user, 100 ether);

        uint256 routerBalanceBefore = IERC20(s_usdc).balanceOf(address(s_conceroRouter));

        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest(address(s_usdc));

        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);
        uint256 conceroFee = s_conceroRouter.getConceroFee(messageRequest.feeToken);

        vm.startPrank(s_user);
        IERC20(s_usdc).approve(address(s_conceroRouter), messageFee);
        s_conceroRouter.conceroSend{value: messageFee}(messageRequest);
        vm.stopPrank();

        uint256 routerBalanceAfter = IERC20(s_usdc).balanceOf(address(s_conceroRouter));
        uint256 relayerFeeEarned = s_conceroRouter.getRelayerFeeEarned(
            s_relayerLib,
            messageRequest.feeToken
        );
        uint256 totalRelayerFeeEarned = s_conceroRouter.exposed_getTotalRelayerFeeEarned(
            messageRequest.feeToken
        );

        assertEq(routerBalanceAfter - routerBalanceBefore, messageFee);
        assertEq(relayerFeeEarned, messageFee - conceroFee);
        assertEq(totalRelayerFeeEarned, messageFee - conceroFee);
    }

    /* getConceroFee */

    function test_getConceroFee_CalculatesCorrectly() public view {
        address feeToken = address(0);
        uint256 conceroFee = s_conceroRouter.getConceroFee(feeToken);

        uint256 expectedConceroFee = (uint256(CONCERO_MESSAGE_FEE_IN_USD) * 1e18) /
            s_conceroPriceFeed.getUsdRate(feeToken);

        assertEq(conceroFee, expectedConceroFee);
    }

    /* getMessageFee */

    function test_getMessageFee_CalculatesCorrectly() public view {
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();

        uint256 relayerFee = MockConceroRelayerLib(payable(s_relayerLib)).getFee(messageRequest);
        uint256 validatorFee = MockConceroValidatorLib(s_validatorLib).getFee(messageRequest);
        uint256 conceroFee = s_conceroRouter.getConceroFee(messageRequest.feeToken);

        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);

        uint256 totalFee = relayerFee + validatorFee + conceroFee;
        assertEq(messageFee, totalFee);
    }

    /* conceroSend */

    function test_conceroSend_EmitsConceroMessageFeePaid() public {
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();

        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);
        uint256 conceroFee = s_conceroRouter.getConceroFee(messageRequest.feeToken);
        uint256 relayerFee = messageFee - conceroFee - VALIDATOR_FEE;

        uint256[] memory validatorsFee = new uint256[](1);
        validatorsFee[0] = VALIDATOR_FEE;

        IConceroRouter.Fee memory fee = IConceroRouter.Fee({
            concero: conceroFee,
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

    function test_conceroSend_RevertsIfUnsupportedFeeToken() public {
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest(s_usdc);

        vm.expectRevert(abi.encodeWithSelector(IConceroRouter.UnsupportedFeeToken.selector));
        vm.prank(s_user);
        s_conceroRouter.conceroSend(messageRequest);
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

    /* withdrawConceroFee */

    function test_withdrawConceroFee_Success() public {
        _conceroSend();

        uint256 expectedConceroFee = s_conceroRouter.getConceroFeeEarned(address(0));

        uint256 balanceBefore = s_deployer.balance;
        address[] memory tokens = new address[](1);

        vm.prank(s_deployer);
        s_conceroRouter.withdrawConceroFee(tokens);

        assertEq(s_deployer.balance, balanceBefore + expectedConceroFee);
    }

    function test_withdrawConceroFee_RevertsIfNotOwner() public {
        _conceroSend();

        address[] memory tokens = new address[](1);

        vm.expectRevert();
        vm.prank(s_user);
        s_conceroRouter.withdrawConceroFee(tokens);
    }

    function testFuzz_withdrawErc20ConceroFeeToken(uint256 earnedFee) public {
        deal(s_usdc, address(s_conceroRouter), earnedFee);

        uint256 conceroFeeEarned = s_conceroRouter.getConceroFeeEarned(s_usdc);
        uint256 deployerBalanceBefore = IERC20(s_usdc).balanceOf(s_deployer);
        address[] memory tokens = new address[](1);
        tokens[0] = s_usdc;

        if (earnedFee > 0) {
            vm.expectEmit(true, true, false, true);
            emit ConceroRouter.ConceroFeeWithdrawn(s_usdc, conceroFeeEarned);
        }

        vm.prank(s_deployer);
        s_conceroRouter.withdrawConceroFee(tokens);

        assertEq(IERC20(s_usdc).balanceOf(s_deployer) - deployerBalanceBefore, conceroFeeEarned);
    }

    /* setConceroMessageFeeInUsd */

    function testFuzz_setConceroMessageFeeInUsd_Success(uint96 newFee) public {
        vm.prank(s_deployer);
        s_conceroRouter.setConceroMessageFeeInUsd(newFee);

        uint256 conceroFee = s_conceroRouter.getConceroFee(address(0));
        uint256 expectedFee = (uint256(newFee) * 1e18) / s_conceroPriceFeed.getUsdRate(address(0));

        assertEq(conceroFee, expectedFee);
    }

    function test_setConceroMessageFeeInUsd_RevertsIfNotOwner() public {
        vm.expectRevert();
        vm.prank(s_user);
        s_conceroRouter.setConceroMessageFeeInUsd(1e6);
    }

    /* isFeeTokenSupported */

    function test_isFeeTokenSupported_ReturnsTrueIfSupported() public view {
        assertTrue(s_conceroRouter.isFeeTokenSupported(address(0)));
    }

    function test_isFeeTokenSupported_ReturnsFalseIfNotSupported() public view {
        assertFalse(s_conceroRouter.isFeeTokenSupported(s_usdc));
    }
}
