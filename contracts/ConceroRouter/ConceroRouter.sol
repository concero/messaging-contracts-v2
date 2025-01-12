// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import "../Libraries/Utils.sol";
import {MessageEventParams, EvmSrcChainData, EvmDstChainData, InternalMessageConfig, FeeToken} from "../Common/MessageTypes.sol";
import {ConceroOwnable} from "../Common/ConceroOwnable.sol";
import {ConceroRouterStorage as s, StorageSlot} from "./ConceroRouterStorage.sol";
import {IConceroClient} from "../Interfaces/IConceroClient.sol";
import {IConceroRouter} from "../Interfaces/IConceroRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MessageLib, MessageConfigConstants} from "../Libraries/MessageLib.sol";
import {OnlyAllowedOperator, OnlyOwner} from "../Common/Errors.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SignerLib} from "../Libraries/SignerLib.sol";
import {SupportedChains} from "../Libraries/SupportedChains.sol";
import {UnsupportedFeeToken, InsufficientFee, MessageAlreadyProcessed, InvalidReceiver} from "./Errors.sol";

contract ConceroRouter is IConceroRouter, ConceroOwnable {
    using SafeERC20 for IERC20;
    using s for s.Router;
    using s for s.PriceFeed;

    /* IMMUTABLE VARIABLES */
    uint24 internal immutable i_chainSelector;
    address internal immutable i_USDC;

    constructor(uint24 chainSelector) ConceroOwnable() {
        i_chainSelector = chainSelector;
    }

    function conceroSend(
        uint256 config,
        bytes calldata dstChainData,
        bytes calldata message
    ) external payable override returns (bytes32 messageId) {
        _collectMessageFee(config, dstChainData);

        (bytes32 _messageId, MessageEventParams memory messageEventParams) = MessageLib
            .buildInternalMessage(config, dstChainData, message, i_chainSelector, s.router().nonce);

        emit ConceroMessageSent(_messageId, messageEventParams);
        return _messageId;
    }

    /**
     * @notice Submits a message report, verifies the signatures, and processes the report data.
     * @param reportSubmission the serialized report data.
     * @param message the message data.
     */
    function submitMessageReport(
        SignerLib.ClfDonReportSubmission calldata reportSubmission,
        bytes calldata message
    ) external {
        // Step 1: Recover and verify the signatures
        SignerLib._verifyClfReportSignatures(reportSubmission);

        // Step 2: Decode the report data
        //        (InternalMessageConfig memory decodedMessageConfig, bytes32 messageId, bytes32 messageHashSum, bytes memory srcData, bytes memory dstData) = SignerLib._extractClfResponse(
        //            reportSubmission.report
        //        );
        //        require(
        //            !s.router().isMessageProcessed[messageId],
        //            MessageAlreadyProcessed(messageId)
        //        );
        //        s.router().isMessageProcessed[messageId] = true;

        // Step 3: Deliver the message
        //        deliverMessage(messageId, dstData, message);
    }

    /**
     * @notice Delivers the message to the receiver contract if valid.
     * @param messageId The unique identifier of the message.
     * @param dstData The destination chain data of the message.
     * @param message The message data.
     */
    function deliverMessage(
        bytes32 messageId,
        EvmDstChainData memory dstData,
        bytes memory message
    ) internal {
        require(dstData.receiver != address(0), InvalidReceiver());
        require(Utils.isContract(dstData.receiver), InvalidReceiver());

        (bool success, bytes memory reason) = dstData.receiver.call{gas: dstData.gasLimit}(
            abi.encodeWithSelector(IConceroClient.conceroReceive.selector, messageId, message)
        );

        if (!success) {
            if (reason.length > 0) {
                revert(string(reason));
            } else {
                revert("ConceroReceive call failed");
            }
        }
    }

    /* OWNER FUNCTIONS */
    function getStorage(StorageSlot slotEnum, bytes32 key) external view returns (uint256) {
        return s._getStorage(slotEnum, key);
    }

    function setStorage(StorageSlot slotEnum, bytes32 key, uint256 value) external onlyOwner {
        s._setStorage(slotEnum, key, value);
    }

    function setStorageBulk(
        StorageSlot[] memory slotEnums,
        bytes32[] memory keys,
        bytes[] memory values
    ) external onlyOwner {
        s._setStorageBulk(slotEnums, keys, values);
    }

    function withdrawFees(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            (bool success, ) = i_owner.call{value: amount}("");
        } else {
            IERC20(token).safeTransfer(i_owner, amount);
        }
    }

    /* INTERNAL FUNCTIONS */
    function _collectMessageFee(uint256 clientMessageConfig, bytes memory dstChainData) internal {
        FeeToken feeToken = FeeToken(
            uint8(clientMessageConfig >> MessageConfigConstants.OFFSET_FEE_TOKEN)
        );
        uint256 messageFee = _calculateMessageFee(clientMessageConfig, dstChainData);

        if (feeToken == FeeToken.native) {
            require(msg.value >= messageFee, InsufficientFee());
            payable(address(this)).transfer(messageFee);
        } else if (feeToken == FeeToken.usdc) {
            IERC20(i_USDC).safeTransferFrom(msg.sender, address(this), messageFee);
        } else {
            revert UnsupportedFeeToken();
        }
    }

    function _calculateMessageFee(
        uint256 clientMessageConfig,
        bytes memory dstChainData
    ) internal view returns (uint256) {
        EvmDstChainData memory evmDstChainData = abi.decode(dstChainData, (EvmDstChainData));

        FeeToken feeToken = FeeToken(
            uint8(clientMessageConfig >> MessageConfigConstants.OFFSET_FEE_TOKEN)
        );
        uint24 dstChainSelector = uint24(
            clientMessageConfig >> MessageConfigConstants.OFFSET_DST_CHAIN
        );
        uint256 baseFee = 0.01 ether;
        uint256 gasPrice = s.priceFeed().lastGasPrices[dstChainSelector];
        uint256 gasFeeNative = gasPrice * evmDstChainData.gasLimit;
        uint256 adjustedGasFeeNative = (gasFeeNative *
            s.priceFeed().nativeNativeRates[dstChainSelector]) / 1 ether;
        uint256 totalFeeNative = baseFee + adjustedGasFeeNative;

        if (feeToken == FeeToken.usdc) {
            return (totalFeeNative * s.priceFeed().nativeUsdcRate) / 1 ether;
        } else if (feeToken == FeeToken.native) {
            return totalFeeNative;
        } else {
            revert UnsupportedFeeToken();
        }
    }

    /* EXTERNAL FUNCTIONS */
    receive() external payable {}

    function getMessageFeeNative(
        uint256 clientMessageConfig,
        bytes memory dstChainData
    ) external view returns (uint256) {
        FeeToken feeToken = FeeToken(
            uint8(clientMessageConfig >> MessageConfigConstants.OFFSET_FEE_TOKEN)
        );
        require(feeToken == FeeToken.native, "InvalidFeeToken");
        return _calculateMessageFee(clientMessageConfig, dstChainData);
    }

    function getMessageFeeUSDC(
        uint256 clientMessageConfig,
        bytes memory dstChainData
    ) external view returns (uint256) {
        FeeToken feeToken = FeeToken(
            uint8(clientMessageConfig >> MessageConfigConstants.OFFSET_FEE_TOKEN)
        );
        require(feeToken == FeeToken.usdc, "InvalidFeeToken");
        return _calculateMessageFee(clientMessageConfig, dstChainData);
    }

    function isChainSupported(uint24 chainSelector) external view returns (bool) {
        return SupportedChains.isChainSupported(chainSelector);
    }
}
