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
import {Message} from "contracts/common/libraries/Message.sol";
import {Namespaces} from "contracts/ConceroRouter/libraries/Storage.sol";
import {RouterSlots} from "contracts/ConceroRouter/libraries/StorageSlots.sol";
import {Types as RouterTypes} from "contracts/ConceroRouter/libraries/Types.sol";

import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {ConceroRouterTest} from "./base/ConceroRouterTest.sol";

contract SendMessage is ConceroRouterTest {
    ConceroTypes.EvmDstChainData internal dstChainData;
    bytes internal message;

    function setUp() public override {
        super.setUp();

        dstChainData = ConceroTypes.EvmDstChainData({
            receiver: address(0x456),
            gasLimit: 1_000_000
        });

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

        uint24[] memory chainselectors = new uint24[](1);
        chainselectors[0] = DST_CHAIN_SELECTOR;
        bool[] memory supported = new bool[](1);
        supported[0] = true;

        vm.startPrank(deployer);
        conceroRouter.setSupportedChains(chainselectors, supported);
        conceroRouter.setNativeNativeRates(chainSelectors, rates);
        conceroRouter.setLastGasPrices(chainSelectors, gasPrices);
        vm.stopPrank();
    }

    function test_conceroSend() public {
        address feeToken = address(0);

        vm.startPrank(user);

        uint256 initialNonce = conceroRouter.getStorage(
            Namespaces.ROUTER,
            RouterSlots.nonce,
            bytes32(0)
        );
        uint256 messageFee = conceroRouter.getMessageFee(
            DST_CHAIN_SELECTOR,
            false,
            feeToken,
            dstChainData
        );

        vm.recordLogs();
        bytes32 messageId = conceroRouter.conceroSend{value: messageFee}(
            DST_CHAIN_SELECTOR,
            false,
            feeToken,
            dstChainData,
            message
        );

        bytes memory srcChainData = abi.encode(
            RouterTypes.EvmSrcChainData({sender: user, blockNumber: block.number})
        );

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool found = false;

        for (uint i = 0; i < entries.length; i++) {
            bytes32 conceroMessageSentEventSig = keccak256(
                "ConceroMessageSent(bytes32,uint8,bool,uint24,bytes,address,bytes)"
            );

            if (entries[i].topics[0] == conceroMessageSentEventSig) {
                found = true;
                (
                    uint8 versionFromEvent,
                    bool shouldFinaliseSrcFromEvent,
                    uint24 dstChainSelectorFromEvent,
                    bytes memory dstChainDataFromEvent,
                    address senderFromEvent,
                    bytes memory messageFromEvent
                ) = abi.decode(entries[i].data, (uint8, bool, uint24, bytes, address, bytes));

                bytes32 messageIdFromEvent = entries[i].topics[1];

                assertEq(dstChainSelectorFromEvent, 8453, "Incorrect dstChainSelector");
                assertEq(
                    senderFromEvent,
                    0x0101010101010101010101010101010101010101,
                    "Incorrect sender"
                );
                assertEq(
                    keccak256(messageFromEvent),
                    keccak256("Test message"),
                    "Incorrect message"
                );
                break;
            }
        }

        assertTrue(found, "ConceroMessageSent event not found");
        uint256 finalNonce = conceroRouter.getStorage(
            Namespaces.ROUTER,
            RouterSlots.nonce,
            bytes32(0)
        );
        assertEq(finalNonce, initialNonce + 1, "Nonce should be incremented by 1");

        //        assertEq(
        //            conceroRouter.getStorage(
        //                Namespaces.ROUTER,
        //                RouterSlots.isMessageSent,
        //                bytes32(messageId)
        //            ),
        //            1,
        //            "Message ID should be marked as sent"
        //        );

        vm.stopPrank();
    }

    function test_RevertInsufficientFee() public {
        uint24 dstChainSelector = DST_CHAIN_SELECTOR;
        bool shouldFinaliseSrc = false;
        address feeToken = address(0);

        vm.startPrank(user);

        uint256 messageFee = conceroRouter.getMessageFee(
            dstChainSelector,
            shouldFinaliseSrc,
            feeToken,
            dstChainData
        );
        uint256 insufficientFee = messageFee - 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                CommonErrors.InsufficientFee.selector,
                insufficientFee,
                messageFee
            )
        );

        conceroRouter.conceroSend{value: insufficientFee}(
            dstChainSelector,
            shouldFinaliseSrc,
            feeToken,
            dstChainData,
            message
        );

        vm.stopPrank();
    }
}
