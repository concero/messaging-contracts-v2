// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

import {Constants} from "../../common/Constants.sol";
import {CommonErrors} from "../../common/CommonErrors.sol";
import {Decoder} from "../../common/libraries/Decoder.sol";

import {Utils as CommonUtils} from "../../common/libraries/Utils.sol";
import {Utils} from "../libraries/Utils.sol";
import {Storage as s} from "../libraries/Storage.sol";
import {Types} from "../libraries/Types.sol";

import {Errors} from "../libraries/Errors.sol";

import {CLFRequestError, MessageReport} from "../../interfaces/IConceroVerifier.sol";
import {Base} from "./Base.sol";

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
        bytes32 requestCLFMessageReportJsCodeHash,
        bytes32 requestOperatorRegistrationJsCodeHash
    ) FunctionsClient(clfRouter) {
        i_clfDonId = clfDonId;
        i_clfSubscriptionId = clfSubscriptionId;
        i_clfDonHostedSecretsVersion = clfDonHostedSecretsVersion;
        i_clfDonHostedSecretsSlotId = clfDonHostedSecretsSlotId;
        i_requestCLFMessageReportJsCodeHash = requestCLFMessageReportJsCodeHash;
        i_requestOperatorRegistrationJsCodeHash = requestOperatorRegistrationJsCodeHash;
    }

    /* IMMUTABLE VARIABLES */
    bytes32 internal immutable i_requestCLFMessageReportJsCodeHash;
    bytes32 internal immutable i_requestOperatorRegistrationJsCodeHash;
    bytes32 internal immutable i_clfDonId;
    uint64 internal immutable i_clfSubscriptionId;
    uint64 internal immutable i_clfDonHostedSecretsVersion;
    uint8 internal immutable i_clfDonHostedSecretsSlotId;
    string internal constant CLF_JS_CODE =
        "try { const [t, p] = await Promise.all([ fetch('https://raw.githubusercontent.com/ethers-io/ethers.js/v6.10.0/dist/ethers.umd.min.js'), fetch('https://raw.githubusercontent.com/concero/v2-contracts/refs/heads/master/clf/dist/requestReport.min.js'), ]); const [e, c] = await Promise.all([t.text(), p.text()]); const g = async s => { return ( '0x' + Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(s)))) .map(v => ('0' + v.toString(16)).slice(-2).toLowerCase()) .join('') ); }; const r = await g(c); const x = await g(e); const b = bytesArgs[0].toLowerCase(); const o = bytesArgs[1].toLowerCase(); if (r === b && x === o) { const ethers = new Function(e + '; return ethers;')(); return await eval(c); } throw new Error(`${r}!=${b}||${x}!=${o}`); } catch (e) { throw new Error(e.message.slice(0, 255));}";
    uint32 internal constant CLF_GAS_LIMIT = 100_000;

    function fulfillRequest(
        bytes32 clfRequestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        //        CLFRequestVersion reportVersion;
        Types.CLFReportType reportType;
        assembly {
            //            reportVersion := byte(1, mload(add(response, 32)))
            reportType := byte(0, mload(add(response, 32)))
        }

        if (reportType == Types.CLFReportType.Message) {
            _handleCLFMessageReport(clfRequestId, response, err);
        } else if (reportType == Types.CLFReportType.OperatorRegistration) {
            _handleCLFOperatorRegistrationReport(clfRequestId, response, err);
        } else {
            emit CLFRequestError(err);
        }

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

        Types.MessageReportResult memory result = Decoder._decodeCLFMessageReportResponse(response);

        uint256 nativeUsdRate = s.priceFeed().nativeUsdRate;

        s.operator().feesEarnedNative[result.operator] += CommonUtils.convertUsdBpsToNative(
            Constants.OPERATOR_FEE_MESSAGE_REPORT_REQUEST_BPS_USD,
            nativeUsdRate
        );

        s.operator().depositsNative[result.operator] += CommonUtils.convertUsdBpsToNative(
            Constants.OPERATOR_DEPOSIT_MESSAGE_REPORT_REQUEST_BPS_USD,
            nativeUsdRate
        );

        emit MessageReport(result.messageId);
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

        require(
            result.operatorChains.length == result.operatorAddresses.length &&
                result.operatorChains.length == result.operatorActions.length,
            CommonErrors.LengthMismatch()
        );

        for (uint256 i = 0; i < result.operatorChains.length; i++) {
            Types.ChainType chainType = result.operatorChains[i];
            Types.OperatorRegistrationAction action = result.operatorActions[i];

            if (chainType == Types.ChainType.EVM) {
                address operatorAddress = address(bytes20(result.operatorAddresses[i]));
                require(operatorAddress == result.operator, Errors.OperatorAddressMismatch());

                if (action == Types.OperatorRegistrationAction.Register) {
                    Utils._addOperator(chainType, result.operatorAddresses[i]);
                    s.operator().isAllowed[result.operator] = true;
                } else if (action == Types.OperatorRegistrationAction.Deregister) {
                    Utils._removeOperator(chainType, result.operatorAddresses[i]);
                    s.operator().isAllowed[result.operator] = false;
                }
            }
        }

        s.operator().depositsNative[result.operator] += CommonUtils.convertUsdBpsToNative(
            Constants.OPERATOR_DEPOSIT_REGISTRATION_REPORT_REQUEST_BPS_USD,
            s.priceFeed().nativeUsdRate
        );

        // emit OperatorRegistered(chainType, operatorAddress);
    }

    /* CLF REQUEST FORMATION */
    function _requestMessageReport(
        Types.MessageReportRequest calldata request
    ) internal returns (bytes32 clfRequestId) {
        _witholdOperatorDeposit(
            msg.sender,
            CommonUtils.convertUsdBpsToNative(
                Constants.OPERATOR_DEPOSIT_MESSAGE_REPORT_REQUEST_BPS_USD,
                s.priceFeed().nativeUsdRate
            )
        );

        bytes[] memory clfReqArgs = new bytes[](6);

        clfReqArgs[0] = abi.encodePacked(i_requestCLFMessageReportJsCodeHash);
        clfReqArgs[1] = abi.encodePacked(request.internalMessageConfig);
        clfReqArgs[2] = abi.encodePacked(request.messageId);
        clfReqArgs[3] = abi.encode(request.messageHashSum);
        clfReqArgs[4] = abi.encode(request.srcChainData);
        clfReqArgs[5] = abi.encode(msg.sender);

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
        Types.ChainType[] calldata chainTypes,
        Types.OperatorRegistrationAction[] calldata operatorActions,
        bytes[] calldata operatorAddresses
    ) internal returns (bytes32 clfRequestId) {
        _witholdOperatorDeposit(
            msg.sender,
            CommonUtils.convertUsdBpsToNative(
                Constants.OPERATOR_DEPOSIT_MESSAGE_REPORT_REQUEST_BPS_USD,
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
        // _witholdOperatorDeposit(msg.sender,  Utils.convertUsdBpsToNative(Constants.OPERATOR_DEPOSIT_MESSAGE_REPORT_REQUEST_BPS_USD, s.priceFeed().nativeUsdRate)
        //        s.verifier().pendingCLFRequests[clfRequestId] = true;
    }

    function _sendCLFRequest(bytes[] memory args) internal returns (bytes32) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(CLF_JS_CODE);
        req.setBytesArgs(args);
        return _sendRequest(req.encodeCBOR(), i_clfSubscriptionId, CLF_GAS_LIMIT, i_clfDonId);
    }

    /**
     * @notice Withholds the required deposit amount from operator's balance
     * @param operator The operator's address
     * @param depositNative The deposit amount in native value
     */
    function _witholdOperatorDeposit(
        address operator,
        uint256 depositNative
    ) internal returns (uint256) {
        require(
            s.operator().depositsNative[operator] >= depositNative,
            Errors.InsufficientOperatorDeposit()
        );

        s.operator().depositsNative[operator] -= depositNative;
        return depositNative;
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
