// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Base} from "./Base.sol";

import {CLFRequestError, MessageReport, MessageReportRequested} from "../../interfaces/IConceroVerifier.sol";
import {CommonErrors} from "../../common/CommonErrors.sol";
import {CommonTypes} from "../../common/CommonTypes.sol";
import {CommonConstants} from "../../common/CommonConstants.sol";

import {Decoder} from "../../common/libraries/Decoder.sol";
import {Errors} from "../libraries/Errors.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {Storage as s} from "../libraries/Storage.sol";

import {Types} from "../libraries/Types.sol";
import {Utils as CommonUtils} from "../../common/libraries/Utils.sol";
import {Utils} from "../libraries/Utils.sol";

abstract contract CLF is FunctionsClient, Base {
    using FunctionsRequest for FunctionsRequest.Request;
    using s for s.Verifier;
    using s for s.Operator;

    constructor(
        address clfRouter,
        bytes32 clfDonId,
        uint64 clfSubscriptionId,
        bytes32 requestCLFMessageReportJsCodeHash,
        bytes32 requestOperatorRegistrationJsCodeHash
    ) FunctionsClient(clfRouter) {
        i_clfDonId = clfDonId;
        i_clfSubscriptionId = clfSubscriptionId;
        i_requestCLFMessageReportJsCodeHash = requestCLFMessageReportJsCodeHash;
        i_requestOperatorRegistrationJsCodeHash = requestOperatorRegistrationJsCodeHash;
    }

    /* IMMUTABLE VARIABLES */
    bytes32 internal immutable i_requestCLFMessageReportJsCodeHash;
    bytes32 internal immutable i_requestOperatorRegistrationJsCodeHash;
    bytes32 internal immutable i_clfDonId;
    uint64 internal immutable i_clfSubscriptionId;
    string internal constant CLF_JS_CODE =
        "var n;((e)=>e[e.H=0]='H')(n||={});var a=await fetch('https://raw.githubusercontent.com/concero/messaging-contracts-v2/refs/heads/master/clf/dist/messageReport.min.js').then((t)=>t.text()),o='0x'+Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(a)))).map((t)=>t.toString(16).padStart(2,'0')).join('');if(o.toLowerCase()!==bytesArgs[0].toLowerCase())throw `${o.toLowerCase()}!==${bytesArgs[0].toLowerCase()}`;return eval(a);";

    function fulfillRequest(
        bytes32 clfRequestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        s.Verifier storage s_verifier = s.verifier();
        require(
            s_verifier.clfRequestStatus[clfRequestId] == Types.CLFRequestStatus.Pending,
            Errors.InvalidClfRequestId(clfRequestId)
        );

        if (err.length > 0) {
            emit CLFRequestError(err);
            s_verifier.clfRequestStatus[clfRequestId] = Types.CLFRequestStatus.Failed;
            return;
        }

        (CommonTypes.ResultConfig memory resultConfig, ) = abi.decode(
            response,
            (CommonTypes.ResultConfig, bytes)
        );

        if (resultConfig.resultType == CommonTypes.ResultType.Message) {
            _handleCLFMessageReport(response);
        } else {
            revert Errors.InvalidClfResultType();
        }

        s_verifier.clfRequestStatus[clfRequestId] = Types.CLFRequestStatus.Fulfilled;
    }

    /* CLF RESPONSE HANDLING */
    function _handleCLFMessageReport(bytes memory response) internal {
        (CommonTypes.ResultConfig memory resultConfig, bytes memory payload) = Decoder
            ._decodeVerifierResult(response);

        if (resultConfig.payloadVersion == 1) {
            _handleMessagePayloadV1(payload);
        } else {
            revert Errors.InvalidMessageVersion();
        }

        _payMsgReportRequestFeeAndRefundGas(resultConfig.requester);
    }

    function _handleMessagePayloadV1(bytes memory payload) internal {
        CommonTypes.MessagePayloadV1 memory decodedPayload = abi.decode(
            payload,
            (CommonTypes.MessagePayloadV1)
        );

        emit MessageReport(decodedPayload.messageId);
    }

    function _payMsgReportRequestFeeAndRefundGas(address requester) internal {
        // s.Operator storage operatorStorage = s.operator();
        // (uint256 nativeUsdRate, uint256 lastGasPrice) = i_conceroPriceFeed
        //     .getNativeUsdRateAndGasPrice();
        // Calculate the gas cost for the request
        // uint256 vrfMsgReportRequestGasCost = s
        //     .config()
        //     .gasFeeConfig
        //     .vrfMsgReportRequestGasOverhead * lastGasPrice;
        // Calculate the operator fee for the request
        // uint256 operatorFeeMessageReportRequest = CommonUtils.convertUsdBpsToNative(
        //     CommonConstants.OPERATOR_FEE_MESSAGE_REPORT_REQUEST_BPS_USD,
        //     nativeUsdRate
        // );
        // Pay operator fee
        // operatorStorage.feesEarnedNative[requester] += operatorFeeMessageReportRequest;
        // operatorStorage.totalFeesEarnedNative += operatorFeeMessageReportRequest;
        // uint256 withheldOperatorAmount = getCLFCost();
        // Return the amount withheld and the gas spent on the request
        // operatorStorage.depositsNative[requester] += totalOperatorRefundGasCost;
        // operatorStorage.totalDepositsNative += vrfMsgReportRequestGasCost;
    }

    /* CLF REQUEST FORMATION */
    function _requestMessageReport(
        bytes32 messageId,
        bytes32 messageHashSum,
        uint24 srcChainSelector,
        bytes memory srcChainData
    ) internal returns (bytes32 clfRequestId) {
        s.Verifier storage verifier = s.verifier();

        uint256 minOperatorDeposit = getCLFCost();
        _witholdOperatorDeposit(msg.sender, minOperatorDeposit);

        bytes[] memory clfReqArgs = new bytes[](6);

        clfReqArgs[0] = abi.encodePacked(i_requestCLFMessageReportJsCodeHash);
        clfReqArgs[1] = abi.encodePacked(srcChainSelector);
        clfReqArgs[2] = abi.encodePacked(messageId);
        clfReqArgs[3] = abi.encodePacked(messageHashSum);
        clfReqArgs[4] = abi.encodePacked(srcChainData);
        clfReqArgs[5] = abi.encodePacked(msg.sender);

        clfRequestId = _sendCLFRequest(clfReqArgs);
        verifier.clfRequestStatus[clfRequestId] = Types.CLFRequestStatus.Pending;
        verifier.clfRequestIdByMessageId[messageId] = clfRequestId;

        emit MessageReportRequested(messageId);
        return clfRequestId;
    }

    function _sendCLFRequest(bytes[] memory args) internal returns (bytes32) {
        s.GasFeeConfig storage gasFeeConfig = s.config().gasFeeConfig;

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(CLF_JS_CODE);
        req.setBytesArgs(args);
        return
            _sendRequest(
                req.encodeCBOR(),
                i_clfSubscriptionId,
                gasFeeConfig.clfCallbackGasLimit,
                i_clfDonId
            );
    }

    function getCLFCost() public view returns (uint256 totalClfCost) {
        s.GasFeeConfig storage gasFeeConfig = s.config().gasFeeConfig;

        (uint256 nativeUsdRate, uint256 lastGasPrice) = i_conceroPriceFeed
            .getNativeUsdRateAndGasPrice();

        // Validate price feed data is available
        require(
            nativeUsdRate > 0,
            CommonErrors.RequiredVariableUnset(CommonErrors.RequiredVariableUnsetType.NativeUSDRate)
        );
        require(
            lastGasPrice > 0,
            CommonErrors.RequiredVariableUnset(CommonErrors.RequiredVariableUnsetType.lastGasPrice)
        );

        // Calculate base gas cost for CLF callback
        uint256 gasCost = (gasFeeConfig.clfCallbackGasOverhead + gasFeeConfig.clfCallbackGasLimit) *
            lastGasPrice;

        // Add over-estimation buffer for gas price volatility
        uint256 overEstimatedGasCost = gasCost +
            ((gasCost * gasFeeConfig.clfGasPriceOverEstimationBps) /
                CommonConstants.BPS_DENOMINATOR);

        require(overEstimatedGasCost > 0, CommonErrors.InvalidAmount());

        uint256 premiumFee = CommonUtils.convertUsdBpsToNative(
            CommonConstants.CLF_PREMIUM_FEE_BPS_USD,
            nativeUsdRate
        );

        totalClfCost = overEstimatedGasCost + premiumFee;
    }

    /**
     * @notice Withholds the required deposit amount from operator's balance
     * @param operator The operator's address
     * @param depositWithholdable The deposit amount in native value
     */
    function _witholdOperatorDeposit(
        address operator,
        uint256 depositWithholdable
    ) internal returns (uint256) {
        s.Operator storage s_operator = s.operator();
        uint256 currentDeposit = s_operator.depositsNative[operator];

        require(
            currentDeposit >= depositWithholdable,
            Errors.InsufficientOperatorDeposit(currentDeposit, depositWithholdable)
        );

        s_operator.depositsNative[operator] -= depositWithholdable;
        return depositWithholdable;
    }
}
