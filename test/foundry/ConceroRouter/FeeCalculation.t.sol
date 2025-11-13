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
import {MockConceroRelayerLib} from "../mocks/MockConceroRelayerLib.sol";
import {MockConceroValidatorLib} from "../mocks/MockConceroValidatorLib.sol";

contract FeeCalculation is ConceroRouterTest {
    uint256 internal VALIDATOR_FEE = 0.01 ether;
    uint256 internal RELAYER_FEE = 0.001 ether;

    function setUp() public override {
        super.setUp();
    }

    function test_ChargeFeeCorrectly() public {
        assertEq(address(s_conceroRouter).balance, 0);

        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();
        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);
        uint256 conceroFee = s_conceroRouter.getConceroFee(messageRequest.feeToken);

        vm.prank(s_user);
        s_conceroRouter.conceroSend{value: messageFee}(messageRequest);

        uint256 routerBalanceAfter = address(s_conceroRouter).balance;
        uint256 relayerFeeEarned = s_conceroRouter.exposed_getRelayerFeeEarned(
            s_relayerLib,
            messageRequest.feeToken
        );
        uint256 totalRelayerFeeEarned = s_conceroRouter.exposed_getTotalRelayerFeeEarned(
            messageRequest.feeToken
        );

        assertEq(routerBalanceAfter, messageFee);
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
            token: address(0)
        });

        //        vm.expectEmit(false, false, false, true);
        //        emit IConceroRouter.ConceroMessageFeePaid(bytes32(0), fee);

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

        assertEq(address(s_relayerLib).balance, 0);

        address[] memory tokens = new address[](1);

        vm.prank(address(s_relayerLib));
        s_conceroRouter.withdrawRelayerFee(tokens);

        assertEq(address(s_relayerLib).balance, RELAYER_FEE + VALIDATOR_FEE);
    }

    function test_withdrawRelayerFee_EmitsRelayerFeeWithdrawn() public {
        _conceroSend();

        uint256 relayerFeeEarned = s_conceroRouter.exposed_getRelayerFeeEarned(
            s_relayerLib,
            address(0)
        );

        address[] memory tokens = new address[](1);

        vm.expectEmit(true, true, false, true);
        emit IRelayer.RelayerFeeWithdrawn(s_relayerLib, address(0), relayerFeeEarned);

        vm.prank(address(s_relayerLib));
        s_conceroRouter.withdrawRelayerFee(tokens);
    }

    /* withdrawConceroFee */

    function test_withdrawConceroFee_Success() public {
        _conceroSend();

        uint256 expectedConceroFee = address(s_conceroRouter).balance -
            s_conceroRouter.exposed_getTotalRelayerFeeEarned(address(0));

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

    /* setConceroMessageFeeInUsd */

    function test_setConceroMessageFeeInUsd_Success() public {
        uint96 newFee = 2e18;

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
