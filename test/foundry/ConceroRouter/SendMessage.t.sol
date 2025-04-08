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
import {Message} from "contracts/common/libraries/Message.sol";
import {Namespaces} from "contracts/ConceroRouter/libraries/Storage.sol";
import {RouterSlots} from "contracts/ConceroRouter/libraries/StorageSlots.sol";
import {Types as RouterTypes} from "contracts/ConceroRouter/libraries/Types.sol";

import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";

import {Message as MessageContract} from "contracts/ConceroRouter/modules/Message.sol";

contract InternalMessageConfigTest {
    uint256 constant OFFSET_DST_CHAIN = 168;
    uint256 constant OFFSET_CALLBACKABLE = 127;

    struct InternalMessageConfig {
        uint24 dstChainSelector;
        uint8 minSrcConfirmations;
        uint8 minDstConfirmations;
        uint8 relayerConfig;
        bool isCallbackable;
        uint8 feeToken;
    }

    function decodeConfigBitwise(
        bytes32 config
    ) public pure returns (uint24 dstChainSelector, bool isCallbackable) {
        dstChainSelector = uint24(uint256(config) >> OFFSET_DST_CHAIN);
        isCallbackable = (uint256(config) & (1 << OFFSET_CALLBACKABLE)) != 0;
    }

    function validateConfigUniversal(uint24 dstChainSelector, bool isCallbackable) public pure {
        if (dstChainSelector == 0) revert("Wrong dst chain selector");
        if (isCallbackable) revert("Wrong isCallbackable");
    }
}

contract SendMessage is ConceroRouterTest {
    bytes internal dstChainData;
    bytes internal message;
    InternalMessageConfigTest internal configTest;

    function setUp() public override {
        super.setUp();

        configTest = new InternalMessageConfigTest();

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

        vm.startPrank(deployer);
        conceroRouter.setNativeNativeRates(chainSelectors, rates);
        conceroRouter.setLastGasPrices(chainSelectors, gasPrices);
        conceroRouter.setIsChainSupported(DST_CHAIN_SELECTOR, true);
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

        bytes32 clientMessageConfig = ConceroUtils._packClientMessageConfig(config);

        uint256 initialNonce = conceroRouter.getStorage(
            Namespaces.ROUTER,
            RouterSlots.nonce,
            bytes32(0)
        );
        uint256 messageFee = conceroRouter.getMessageFee(clientMessageConfig, dstChainData);

        vm.recordLogs();
        bytes32 messageId = conceroRouter.conceroSend{value: messageFee}(
            clientMessageConfig,
            dstChainData,
            message
        );

        bytes memory srcChainData = abi.encode(
            RouterTypes.EvmSrcChainData({sender: user, blockNumber: block.number})
        );

        // TODO: vm.expectEmit can be used instead of it
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool foundEvent = false;
        for (uint i = 0; i < entries.length; i++) {
            if (
                entries[i].topics[0] ==
                keccak256("ConceroMessageSent(bytes32,bytes32,bytes,bytes,bytes)")
            ) {
                foundEvent = true;

                bytes32 internalMessageConfig = bytes32(entries[i].topics[1]);
                bytes32 emittedMessageId = bytes32(entries[i].topics[2]);

                console.logBytes32(clientMessageConfig);
                console.logBytes32(emittedMessageId);

                (bytes memory dstChainDataFromEvent, bytes memory messageFromEvent) = abi.decode(
                    entries[i].data,
                    (bytes, bytes)
                );

                Message.validateInternalMessage(
                    internalMessageConfig,
                    srcChainData,
                    dstChainDataFromEvent
                );

                assertEq(emittedMessageId, messageId, "Message ID mismatch");
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

    function test_CompareInternalMessageConfigGasUsageBitwise() public {
        // 6455

        bytes32 configAsBitmap = 0x0000000000000000002105000100010000000000000000000000000000000001;
        (uint24 dstChain1, bool isCallbackable1) = configTest.decodeConfigBitwise(configAsBitmap);
        configTest.validateConfigUniversal(dstChain1, isCallbackable1);
    }

    function test_CompareInternalMessageConfigGasUsageStruct() public {
        // 5712

        InternalMessageConfigTest.InternalMessageConfig
            memory configAsStruct = InternalMessageConfigTest.InternalMessageConfig({
                dstChainSelector: DST_CHAIN_SELECTOR,
                minSrcConfirmations: 1,
                minDstConfirmations: 1,
                relayerConfig: 0,
                isCallbackable: false,
                feeToken: 0
            });

        configTest.validateConfigUniversal(
            configAsStruct.dstChainSelector,
            configAsStruct.isCallbackable
        );
    }

    function test_sendMessageV1() public {
        // 88929 88665
        ConceroTypes.ClientMessageConfig memory config = ConceroTypes.ClientMessageConfig({
            dstChainSelector: DST_CHAIN_SELECTOR,
            minSrcConfirmations: 1,
            minDstConfirmations: 1,
            relayerConfig: 0,
            isCallbackable: false,
            feeToken: ConceroTypes.FeeToken.native
        });

        bytes32 clientMessageConfig = ConceroUtils._packClientMessageConfig(config); // 3346 gas
        uint256 messageFee = conceroRouter.getMessageFee(clientMessageConfig, dstChainData);
        vm.resetGasMetering();
        conceroRouter.conceroSend{value: messageFee}(clientMessageConfig, dstChainData, message);
        vm.pauseGasMetering();
    }

    function test_sendMessageV2() public {
        // 88623 88515
        vm.startPrank(user);

        ConceroTypes.ClientMessageConfig memory config = ConceroTypes.ClientMessageConfig({
            dstChainSelector: DST_CHAIN_SELECTOR,
            minSrcConfirmations: 1,
            minDstConfirmations: 1,
            relayerConfig: 0,
            isCallbackable: false,
            feeToken: ConceroTypes.FeeToken.native
        });

        uint256 messageFee = conceroRouter.getMessageFee(
            config.dstChainSelector,
            dstChainData,
            config.feeToken
        );
        vm.resetGasMetering();
        conceroRouter.conceroSendV2{value: messageFee}(config, dstChainData, message); // 58811
        vm.pauseGasMetering();
    }

    function test_sendMessageV3() public {
        // 86879
        vm.startPrank(user);

        ConceroTypes.ClientMessageConfig memory config = ConceroTypes.ClientMessageConfig({
            dstChainSelector: DST_CHAIN_SELECTOR,
            minSrcConfirmations: 1,
            minDstConfirmations: 1,
            relayerConfig: 0,
            isCallbackable: false,
            feeToken: ConceroTypes.FeeToken.native
        });

        uint256 messageFee = conceroRouter.getMessageFee(
            config.dstChainSelector,
            dstChainData,
            config.feeToken
        );
        vm.resetGasMetering();
        conceroRouter.conceroSendV3{value: messageFee}(config, dstChainData, message); // 56832
        vm.pauseGasMetering();
    }

    function test_sendMessageWithOffchainConfig() public {
        // 85765
        vm.startPrank(user);

        bytes32 config = 0x0000000000000000002105000100010000000000000000000000000000000000;

        uint256 messageFee = conceroRouter.getMessageFee(
            DST_CHAIN_SELECTOR,
            dstChainData,
            ConceroTypes.FeeToken.native
        );

        vm.resetGasMetering();
        conceroRouter.conceroSend{value: messageFee}(config, dstChainData, message); // conceroSend - 56101
        vm.pauseGasMetering();
    }

    function test_RevertInsufficientFee() public {
        vm.startPrank(user);

        uint256 messageFee = conceroRouter.getMessageFee(i_clientMessageConfig, dstChainData);
        uint256 insufficientFee = messageFee - 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                CommonErrors.InsufficientFee.selector,
                insufficientFee,
                messageFee
            )
        );

        conceroRouter.conceroSend{value: insufficientFee}(
            i_clientMessageConfig,
            dstChainData,
            message
        );

        vm.stopPrank();
    }

    function test_RevertInvalidMessageConfig() public {
        vm.startPrank(user);

        bytes32 invalidConfig = bytes32(0);
        uint256 messageFee = conceroRouter.getMessageFee(i_clientMessageConfig, dstChainData);

        vm.expectRevert();
        conceroRouter.conceroSend{value: messageFee}(invalidConfig, dstChainData, message);

        vm.stopPrank();
    }
}
