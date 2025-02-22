// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Vm} from "forge-std/src/Vm.sol";
import {console} from "forge-std/src/Console.sol";

import {ConceroTypes} from "contracts/ConceroClient/ConceroTypes.sol";
import {ConceroUtils} from "contracts/ConceroClient/ConceroUtils.sol";
import {Message, MessageConfigBitOffsets} from "contracts/common/libraries/Message.sol";
import {Namespaces} from "contracts/ConceroRouter/libraries/Storage.sol";
import {RouterSlots} from "contracts/ConceroRouter/libraries/StorageSlots.sol";
import {Types as RouterTypes} from "contracts/ConceroRouter/libraries/Types.sol";

import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";

contract SendMessage is ConceroRouterTest {
    bytes internal dstChainData;
    bytes internal message;

    function setUp() public override {
        super.setUp();

        dstChainData = abi.encode(
            RouterTypes.EvmDstChainData({receiver: address(0x456), gasLimit: 1_000_000})
        );
        message = "Test message";

        vm.deal(user, 100 ether);

        vm.prank(deployer);
        conceroRouter.setNativeUsdRate(NATIVE_USD_RATE);
        uint24[] memory chainSelectors = new uint24[](1);
        chainSelectors[0] = DST_CHAIN_SELECTOR;

        uint256[] memory rates = new uint256[](1);
        rates[0] = 1;

        uint256[] memory gasPrices = new uint256[](1);
        gasPrices[0] = 100_000; // 0.1 gwei

        vm.prank(deployer);
        conceroRouter.setNativeNativeRates(chainSelectors, rates);

        vm.prank(deployer);
        conceroRouter.setLastGasPrices(chainSelectors, gasPrices);
    }

    function test_conceroSend() public {
        vm.startPrank(user);

        ConceroTypes.ClientMessageConfig memory config = ConceroTypes.ClientMessageConfig({
            dstChainSelector: DST_CHAIN_SELECTOR,
            minSrcConfirmations: 1,
            minDstConfirmations: 1,
            relayerConfig: 0,
            isCallbackable: false,
            feeToken: ConceroTypes.FeeToken.native
        });

        uint256 clientMessageConfig = ConceroUtils._packClientMessageConfig(config);

        uint256 initialNonce = conceroRouter.getStorage(
            Namespaces.ROUTER,
            RouterSlots.nonce,
            bytes32(0)
        );
        uint256 messageFee = conceroRouter.getMessageFeeNative(clientMessageConfig, dstChainData);

        vm.recordLogs();
        bytes32 messageId = conceroRouter.conceroSend{value: messageFee}(
            clientMessageConfig,
            dstChainData,
            message
        );

        bytes memory srcChainData = abi.encode(
            RouterTypes.EvmSrcChainData({sender: user, blockNumber: block.number})
        );

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool foundEvent = false;
        for (uint i = 0; i < entries.length; i++) {
            if (
                entries[i].topics[0] == keccak256("ConceroMessageSent(bytes32,uint256,bytes,bytes)")
            ) {
                foundEvent = true;
                (
                    uint256 internalMessageConfig,
                    bytes memory dstChainDataFromEvent,
                    bytes memory messageFromEvent
                ) = abi.decode(entries[i].data, (uint256, bytes, bytes));

                Message.validateInternalMessage(
                    internalMessageConfig,
                    srcChainData,
                    dstChainDataFromEvent
                );

                assertEq(entries[i].topics[1], messageId, "Message ID mismatch");
                assertEq(dstChainDataFromEvent, dstChainData, "Destination chain data mismatch");
                assertEq(messageFromEvent, message, "Message mismatch");
            }
        }
        assertTrue(foundEvent, "ConceroMessageSent event not found");

        uint256 finalNonce = conceroRouter.getStorage(
            Namespaces.ROUTER,
            RouterSlots.nonce,
            bytes32(0)
        );
        assertEq(finalNonce, initialNonce + 1, "Nonce should be incremented by 1");

        //        assertEq(
        //            conceroRouter.getStorage(Namespaces.ROUTER, RouterSlots.isMessageSent, bytes32(messageId)),
        //            1
        //        );

        vm.stopPrank();
    }

    function test_RevertInsufficientFee() public {
        vm.startPrank(user);

        uint256 messageFee = conceroRouter.getMessageFeeNative(CLIENT_MESSAGE_CONFIG, dstChainData);
        uint256 insufficientFee = messageFee - 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                CommonErrors.InsufficientFee.selector,
                insufficientFee,
                messageFee
            )
        );

        conceroRouter.conceroSend{value: insufficientFee}(
            CLIENT_MESSAGE_CONFIG,
            dstChainData,
            message
        );

        vm.stopPrank();
    }

    function test_RevertInvalidMessageConfig() public {
        vm.startPrank(user);

        uint256 invalidConfig = 0;
        uint256 messageFee = conceroRouter.getMessageFeeNative(CLIENT_MESSAGE_CONFIG, dstChainData);

        vm.expectRevert();
        conceroRouter.conceroSend{value: messageFee}(invalidConfig, dstChainData, message);

        vm.stopPrank();
    }
}
