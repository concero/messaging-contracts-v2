// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {console} from "forge-std/src/console.sol";

import {Base} from "./Base.sol";

import {CLFRequestError, MessageReport, OperatorRegistered} from "../../interfaces/IConceroVerifier.sol";
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
        uint64 clfDonHostedSecretsVersion,
        uint8 clfDonHostedSecretsSlotId,
        uint16 clfPremiumFeeUsdBps,
        uint32 clfCallbackGasLimit,
        bytes32 requestCLFMessageReportJsCodeHash,
        bytes32 requestOperatorRegistrationJsCodeHash
    ) FunctionsClient(clfRouter) {
        i_clfDonId = clfDonId;
        i_clfSubscriptionId = clfSubscriptionId;
        i_clfDonHostedSecretsVersion = clfDonHostedSecretsVersion;
        i_clfDonHostedSecretsSlotId = clfDonHostedSecretsSlotId;
        i_clfPremiumFeeUsdBps = clfPremiumFeeUsdBps;
        i_clfCallbackGasLimit = clfCallbackGasLimit;
        i_requestCLFMessageReportJsCodeHash = requestCLFMessageReportJsCodeHash;
        i_requestOperatorRegistrationJsCodeHash = requestOperatorRegistrationJsCodeHash;
    }

    /* IMMUTABLE VARIABLES */
    bytes32 internal immutable i_requestCLFMessageReportJsCodeHash;
    bytes32 internal immutable i_requestOperatorRegistrationJsCodeHash;
    bytes32 internal immutable i_clfDonId;
    uint64 internal immutable i_clfSubscriptionId;
    uint64 internal immutable i_clfDonHostedSecretsVersion;
    uint16 internal immutable i_clfPremiumFeeUsdBps;
    uint32 internal immutable i_clfCallbackGasLimit;
    uint8 internal immutable i_clfDonHostedSecretsSlotId;
    string internal constant CLF_JS_CODE =
        "var n;((e)=>e[e.H=0]='H')(n||={});var a=await fetch('https://raw.githubusercontent.com/concero/v2-contracts/refs/heads/master/clf/dist/messageReport.min.js').then((t)=>t.text()),o='0x'+Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(a)))).map((t)=>t.toString(16).padStart(2,'0')).join('');if(o!==bytesArgs[0])throw 'hash mismatch';return eval(a);";
    uint32 internal constant CLF_GAS_LIMIT = 100_000;

    function fulfillRequest(
        bytes32 clfRequestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        CommonTypes.CLFReportType reportType;
        assembly {
            reportType := byte(0, mload(add(response, 32)))
        }

        // @dev TODO: where is isPending check?

        if (reportType == CommonTypes.CLFReportType.Message) {
            _handleCLFMessageReport(clfRequestId, response, err);
        } else if (reportType == CommonTypes.CLFReportType.OperatorRegistration) {
            _handleCLFOperatorRegistrationReport(clfRequestId, response, err);
        } else {
            emit CLFRequestError(err);
        }

        // @dev TODO: move the check to the top of the function
        delete s.verifier().pendingCLFRequests[clfRequestId];
    }

    /* CLF RESPONSE HANDLING */
    function _handleCLFMessageReport(
        bytes32 clfRequestId,
        bytes memory response,
        bytes memory err
    ) internal {
        if (err.length != 0) {
            emit CLFRequestError(err);
            return;
        }

        CommonTypes.ClfReportResult memory result = Decoder._decodeCLFMessageReportResponse(
            response
        );

        (, uint8 reportVersion, address requester) = Decoder._decodeCLFReportConfig(
            result.reportConfig
        );

        if (reportVersion == 1) {
            _handleClfReportV1(result.encodedReportData);
        }

        uint256 nativeUsdRate = s.priceFeed().nativeUsdRate;

        s.operator().feesEarnedNative[requester] += CommonUtils.convertUsdBpsToNative(
            CommonConstants.OPERATOR_FEE_MESSAGE_REPORT_REQUEST_BPS_USD,
            nativeUsdRate
        );

        s.operator().depositsNative[requester] += CommonUtils.convertUsdBpsToNative(
            CommonConstants.OPERATOR_DEPOSIT_MESSAGE_REPORT_REQUEST_BPS_USD,
            nativeUsdRate
        );
    }

    function _handleClfReportV1(bytes memory encodedReportData) internal {
        CommonTypes.ClfMessageReportDataV1 memory decodedClfReportData = abi.decode(
            encodedReportData,
            (CommonTypes.ClfMessageReportDataV1)
        );

        emit MessageReport(decodedClfReportData.messageId);
    }

    function _handleCLFOperatorRegistrationReport(
        bytes32 clfRequestId,
        bytes memory response,
        bytes memory err
    ) internal {
        if (err.length != 0) {
            emit CLFRequestError(err);
            return;
        }

        Types.OperatorRegistrationResult memory result = Decoder
            ._decodeCLFOperatorRegistrationReport(response);

        (, , address requester) = Decoder._decodeCLFReportConfig(result.reportConfig);

        require(
            result.operatorChains.length == result.operatorAddresses.length &&
                result.operatorChains.length == result.operatorActions.length,
            CommonErrors.LengthMismatch()
        );

        for (uint256 i = 0; i < result.operatorChains.length; i++) {
            CommonTypes.ChainType chainType = result.operatorChains[i];
            Types.OperatorRegistrationAction action = result.operatorActions[i];

            if (chainType == CommonTypes.ChainType.EVM) {
                bytes memory addressBytes = result.operatorAddresses[i];

                address operatorAddress = abi.decode(addressBytes, (address));
                require(operatorAddress == requester, Errors.OperatorAddressMismatch());

                if (action == Types.OperatorRegistrationAction.Register) {
                    Utils._addOperator(chainType, abi.encodePacked(operatorAddress));
                    s.operator().isRegistered[requester] = true;
                } else if (action == Types.OperatorRegistrationAction.Deregister) {
                    Utils._removeOperator(chainType, abi.encodePacked(operatorAddress));
                    s.operator().isRegistered[requester] = false;
                }
            }
        }

        emit OperatorRegistered(requester, result.operatorChains, result.operatorActions);
    }

    /* CLF REQUEST FORMATION */
    function _requestMessageReport(
        bytes32 internalMessageConfig,
        bytes32 messageId,
        bytes32 messageHashSum,
        bytes memory srcChainData
    ) internal returns (bytes32 clfRequestId) {
        _witholdOperatorDeposit(
            msg.sender,
            CommonUtils.convertUsdBpsToNative(
                CommonConstants.OPERATOR_DEPOSIT_MESSAGE_REPORT_REQUEST_BPS_USD,
                s.priceFeed().nativeUsdRate
            )
        );

        bytes[] memory clfReqArgs = new bytes[](6);

        clfReqArgs[0] = abi.encodePacked(i_requestCLFMessageReportJsCodeHash);
        clfReqArgs[1] = abi.encodePacked(internalMessageConfig);
        clfReqArgs[2] = abi.encodePacked(messageId);
        clfReqArgs[3] = abi.encodePacked(messageHashSum);
        clfReqArgs[4] = abi.encodePacked(srcChainData);
        clfReqArgs[5] = abi.encodePacked(msg.sender);

        clfRequestId = _sendCLFRequest(clfReqArgs);
        s.verifier().pendingCLFRequests[clfRequestId] = true;
        return clfRequestId;
    }

    /**
     * @notice Requests operator registration through CLF
     * @param chainTypes Array of chain types for operator registration
     * @param operatorActions Array of registration actions for the operator
     * @param operatorAddresses Array of operator addresses for registration
     * @return clfRequestId The unique identifier for the CLF request
     */
    function _requestOperatorRegistration(
        CommonTypes.ChainType[] calldata chainTypes,
        Types.OperatorRegistrationAction[] calldata operatorActions,
        bytes[] calldata operatorAddresses
    ) internal returns (bytes32 clfRequestId) {
        _witholdOperatorDeposit(
            msg.sender,
            CommonUtils.convertUsdBpsToNative(
                CommonConstants.OPERATOR_DEPOSIT_MESSAGE_REPORT_REQUEST_BPS_USD,
                s.priceFeed().nativeUsdRate
            )
        );

        bytes[] memory clfReqArgs = new bytes[](5);

        clfReqArgs[0] = abi.encodePacked(i_requestOperatorRegistrationJsCodeHash);
        clfReqArgs[1] = abi.encode(chainTypes);
        clfReqArgs[2] = abi.encode(operatorActions);
        clfReqArgs[3] = abi.encode(operatorAddresses);
        clfReqArgs[4] = abi.encode(msg.sender);

        clfRequestId = _sendCLFRequest(clfReqArgs);
        s.verifier().pendingCLFRequests[clfRequestId] = true;

        return clfRequestId;
    }

    function _requestOperatorDeregistration() internal {
        // _witholdOperatorDeposit(msg.sender,  Utils.convertUsdBpsToNative(CommonConstants.sol.OPERATOR_DEPOSIT_MESSAGE_REPORT_REQUEST_BPS_USD, s.priceFeed().nativeUsdRate)
        //        s.verifier().pendingCLFRequests[clfRequestId] = true;
    }

    function _sendCLFRequest(bytes[] memory args) internal returns (bytes32) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(CLF_JS_CODE);
        req.setBytesArgs(args);
        return _sendRequest(req.encodeCBOR(), i_clfSubscriptionId, CLF_GAS_LIMIT, i_clfDonId);
    }

    function getCLFDeposit() public view returns (uint256 depositNative) {
        uint256 lastGasPrice = s.priceFeed().lastGasPrices[i_chainSelector];
        require(
            lastGasPrice > 0,
            CommonErrors.RequiredVariableUnset(CommonErrors.RequiredVariableUnsetType.lastGasPrice)
        );

        uint256 gasCost = i_clfCallbackGasLimit * lastGasPrice;

        uint256 premiumFee = CommonUtils.convertUsdBpsToNative(
            i_clfPremiumFeeUsdBps,
            s.priceFeed().nativeUsdRate
        );

        return gasCost + premiumFee;
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
        uint256 currentDeposit = s.operator().depositsNative[operator];
        require(
            s.operator().depositsNative[operator] >= depositWithholdable,
            Errors.InsufficientOperatorDeposit(currentDeposit, depositWithholdable)
        );

        s.operator().depositsNative[operator] -= depositWithholdable;
        return depositWithholdable;
    }

    //    /**
    //     * @notice Returns the operator's deposit amount
    //     * @param operator The operator's address
    //     * @param depositNative The deposit amount in native value
    //     * @return The operator's deposit amount
    //     */
    //    function _returnOperatorDeposit(
    //        address operator,
    //        uint256 depositNative
    //    ) internal returns (uint256) {
    //        s.operator().depositNative[operator] += depositNative;
    //        return depositNative;
    //    }
}
