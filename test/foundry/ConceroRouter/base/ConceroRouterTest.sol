// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Vm} from "forge-std/src/Vm.sol";
import {console} from "forge-std/src/console.sol";

import {MockConceroRelayerLib} from "../../mocks/MockConceroRelayerLib.sol";
import {ConceroRouterHarness} from "../../harnesses/ConceroRouterHarness.sol";
import {ConceroTestClient} from "../../ConceroTestClient/ConceroTestClient.sol";
import {ConceroTest} from "../../utils/ConceroTest.sol";
import {DeployConceroRouter} from "../../scripts/deploy/DeployConceroRouter.s.sol";
import {MockConceroValidatorLib} from "../../mocks/MockConceroValidatorLib.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {MessageCodec} from "contracts/common/libraries/MessageCodec.sol";

abstract contract ConceroRouterTest is ConceroTest {
    ConceroTestClient internal s_conceroClient;
    ConceroRouterHarness internal s_conceroRouter;
    ConceroRouterHarness internal s_dstConceroRouter;

    address internal s_validatorLib = address(new MockConceroValidatorLib());
    address internal s_relayerLib = address(new MockConceroRelayerLib());

    function setUp() public virtual {
        s_conceroRouter = ConceroRouterHarness(
            payable(
                (new DeployConceroRouter()).deploy(SRC_CHAIN_SELECTOR, address(s_conceroPriceFeed))
            )
        );

        s_dstConceroRouter = ConceroRouterHarness(
            payable(
                (new DeployConceroRouter()).deploy(DST_CHAIN_SELECTOR, address(s_conceroPriceFeed))
            )
        );

        vm.startPrank(s_deployer);
        s_conceroRouter.setConceroMessageFeeInUsd(CONCERO_MESSAGE_FEE_IN_USD);
        s_conceroRouter.setMaxMessageSize(MAX_CONCERO_MESSAGE_SIZE);
        s_conceroRouter.setMaxValidatorsCount(MAX_CONCERO_VALIDATORS_COUNT);
        //        s_conceroRouter.setTokenPriceFeed(address(0), address(s_conceroPriceFeed));
        vm.stopPrank();

        s_conceroClient = new ConceroTestClient(payable(s_dstConceroRouter));
        s_conceroClient.setIsRelayerAllowed(s_relayerLib, true);
        s_conceroClient.setIsValidatorAllowed(s_validatorLib, true);
        s_conceroClient.setRequiredValidatorsCount(1);

        vm.deal(s_user, 100 ether);

        vm.prank(s_feedUpdater);
        s_conceroPriceFeed.setNativeUsdRate(NATIVE_USD_RATE);
        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = DST_CHAIN_SELECTOR;

        uint256[] memory rates = new uint256[](1);
        rates[0] = 1;

        uint256[] memory gasPrices = new uint256[](1);
        gasPrices[0] = 100_000; // 0.1 gwei

        vm.startPrank(s_feedUpdater);
        s_conceroPriceFeed.setNativeNativeRates(chainSelectors, rates);
        s_conceroPriceFeed.setLastGasPrices(chainSelectors, gasPrices);
        vm.stopPrank();
    }

    // helpers

    function _buildMessageRequest(
        bytes memory payload,
        uint32 dstChainGasLimit,
        uint64 srcBlockConfirmations
    ) internal view returns (IConceroRouter.MessageRequest memory) {
        return _buildMessageRequest(payload, dstChainGasLimit, srcBlockConfirmations, address(0));
    }

    function _buildMessageRequest(
        address[] memory validatorLibs
    ) internal view returns (IConceroRouter.MessageRequest memory) {
        IConceroRouter.MessageRequest memory req = _buildMessageRequest();
        req.validatorLibs = validatorLibs;
        return req;
    }

    function _buildMessageRequest(
        bytes memory payload
    ) internal view returns (IConceroRouter.MessageRequest memory) {
        return _buildMessageRequest(payload, 300_000, 10, address(0));
    }

    function _buildMessageRequest(
        address feeToken
    ) internal view returns (IConceroRouter.MessageRequest memory) {
        return _buildMessageRequest("Test message", 300_000, 10, feeToken);
    }

    function _buildMessageRequest() internal view returns (IConceroRouter.MessageRequest memory) {
        return _buildMessageRequest("Test message", 300_000, 10, address(0));
    }

    function _buildMessageRequest(
        bytes memory payload,
        uint32 dstChainGasLimit,
        uint64 srcBlockConfirmations,
        address feeToken
    ) internal view returns (IConceroRouter.MessageRequest memory) {
        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        return
            IConceroRouter.MessageRequest({
                dstChainSelector: DST_CHAIN_SELECTOR,
                srcBlockConfirmations: srcBlockConfirmations,
                feeToken: feeToken,
                dstChainData: MessageCodec.encodeEvmDstChainData(
                    address(s_conceroClient),
                    dstChainGasLimit
                ),
                validatorLibs: validatorLibs,
                relayerLib: s_relayerLib,
                validatorConfigs: new bytes[](1),
                relayerConfig: new bytes(1),
                payload: payload
            });
    }

    function _conceroSend() internal returns (bytes32 messageId, bytes memory messageReceipt) {
        vm.recordLogs();
        IConceroRouter.MessageRequest memory messageRequest = _buildMessageRequest();
        uint256 messageFee = s_conceroRouter.getMessageFee(messageRequest);

        vm.prank(s_user);
        s_conceroRouter.conceroSend{value: messageFee}(messageRequest);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        messageId = bytes32(entries[0].topics[1]);
        messageReceipt = abi.decode(entries[0].data, (bytes));

        return (messageId, messageReceipt);
    }
}
