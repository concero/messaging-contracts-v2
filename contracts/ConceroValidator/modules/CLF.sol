// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;



import {Base} from "../../common/Base.sol";
import {CommonErrors} from "../../common/CommonErrors.sol";
import {CommonTypes} from "../../common/CommonTypes.sol";
import {Decoder} from "../../common/libraries/Decoder.sol";
import {Errors} from "../libraries/Errors.sol";
import {FunctionsClient, FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";

import {Storage as s} from "../libraries/Storage.sol";
import {Types} from "../libraries/Types.sol";
import {Utils as CommonUtils} from "../../common/libraries/Utils.sol";

abstract contract CLF is FunctionsClient, Base {
    using FunctionsRequest for FunctionsRequest.Request;
    using s for s.Validator;

    event CLFRequestError(bytes err);
    event MessageReport(bytes32 indexed messageId);
    event MessageReportRequested(bytes32 indexed messageId);

    constructor(
        address clfRouter,
        bytes32 clfDonId,
        uint64 clfSubscriptionId,
        bytes32 requestCLFMessageReportJsCodeHash
    ) FunctionsClient(clfRouter) {
        i_clfDonId = clfDonId;
        i_clfSubscriptionId = clfSubscriptionId;
        i_requestCLFMessageReportJsCodeHash = requestCLFMessageReportJsCodeHash;
    }

    bytes32 internal immutable i_requestCLFMessageReportJsCodeHash;
    bytes32 internal immutable i_clfDonId;
    uint64 internal immutable i_clfSubscriptionId;
    string internal constant CLF_JS_CODE =
        "var n;((e)=>e[e.H=0]='H')(n||={});var a=await fetch('https://raw.githubusercontent.com/concero/messaging-contracts-v2/refs/heads/master/clf/dist/messageReport.min.js').then((t)=>t.text()),o='0x'+Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(a)))).map((t)=>t.toString(16).padStart(2,'0')).join('');if(o.toLowerCase()!==bytesArgs[0].toLowerCase())throw `${o.toLowerCase()}!==${bytesArgs[0].toLowerCase()}`;return eval(a);";

    /* CLF Response Handling */

    function fulfillRequest(
        bytes32 clfRequestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        s.Validator storage s_validator = s.validator();
        require(
            s_validator.clfRequestStatus[clfRequestId] == Types.CLFRequestStatus.Pending,
            Errors.InvalidClfRequestId(clfRequestId)
        );

        if (err.length > 0) {
            emit CLFRequestError(err);
            s_validator.clfRequestStatus[clfRequestId] = Types.CLFRequestStatus.Failed;
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

        s_validator.clfRequestStatus[clfRequestId] = Types.CLFRequestStatus.Fulfilled;
    }

    function _handleCLFMessageReport(bytes memory response) private {
        (CommonTypes.ResultConfig memory resultConfig, bytes memory payload) = Decoder
            ._decodeVerifierResult(response);

        if (resultConfig.payloadVersion == 1) {
            _handleMessagePayloadV1(payload);
        } else {
            revert Errors.InvalidMessageVersion();
        }
    }

    function _handleMessagePayloadV1(bytes memory payload) private {
        CommonTypes.MessagePayloadV1 memory decodedPayload = abi.decode(
            payload,
            (CommonTypes.MessagePayloadV1)
        );

        emit MessageReport(decodedPayload.messageId);
    }

    /* CLF Request Formation */

    function _requestMessageReport(
        bytes32 messageId,
        uint24 srcChainSelector,
        bytes memory srcChainData
    ) internal returns (bytes32 clfRequestId) {
        s.Validator storage s_validator = s.validator();

        _chargeMsgReportRequestFee(msg.sender, s_validator);

        bytes[] memory clfReqArgs = new bytes[](6);

        clfReqArgs[0] = abi.encodePacked(i_requestCLFMessageReportJsCodeHash);
        clfReqArgs[1] = abi.encodePacked(srcChainSelector);
        clfReqArgs[2] = abi.encodePacked(messageId);
        clfReqArgs[3] = abi.encodePacked(srcChainData);
        clfReqArgs[4] = abi.encodePacked(msg.sender);

        clfRequestId = _sendCLFRequest(clfReqArgs);
        s_validator.clfRequestStatus[clfRequestId] = Types.CLFRequestStatus.Pending;
        s_validator.clfRequestIdByMessageId[messageId] = clfRequestId;

        emit MessageReportRequested(messageId);
        return clfRequestId;
    }

    function _chargeMsgReportRequestFee(address s_relayer, s.Validator storage validator) private {
        uint256 reportRequestFee = getCLFCost();
        uint256 currentDeposit = validator.depositsNative[s_relayer];

        require(
            currentDeposit >= reportRequestFee,
            Errors.InsufficientDeposit(currentDeposit, reportRequestFee)
        );

        validator.totalNativeFees += reportRequestFee;
        validator.depositsNative[s_relayer] -= reportRequestFee;
    }

    function _sendCLFRequest(bytes[] memory args) private returns (bytes32) {
        s.GasFeeConfig storage gasFeeConfig = s.validator().gasFeeConfig;

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

    /* Getters */

    function getCLFCost() public view returns (uint256 totalClfCost) {
        s.GasFeeConfig storage gasFeeConfig = s.validator().gasFeeConfig;

        (uint256 nativeUsdRate, uint256 lastGasPrice) = i_conceroPriceFeed
            .getNativeUsdRateAndGasPrice();

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

    function getClfRequestIdStatus(
        bytes32 clfRequestId
    ) public view returns (Types.CLFRequestStatus) {
        return s.validator().clfRequestStatus[clfRequestId];
    }
}
