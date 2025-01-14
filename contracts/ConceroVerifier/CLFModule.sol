// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

import {SignerLib} from "../Libraries/SignerLib.sol";
import {DecoderLib} from "../Libraries/DecoderLib.sol";

import {IConceroVerifier, CLFRequestError, CLFReportType, ChainType, CLFRequestStatus, MessageReport, MessageReportRequest, MessageReportResult} from "../Interfaces/IConceroVerifier.sol";
import {ConceroVerifierStorage as s} from "./ConceroVerifierStorage.sol";
import {BaseModule} from "./BaseModule.sol";
import {CommonConstants} from "../Common/CommonConstants.sol";
import {InsufficientOperatorDeposit} from "./Errors.sol";

abstract contract CLFModule is FunctionsClient, BaseModule {
    using FunctionsRequest for FunctionsRequest.Request;
    using s for s.Verifier;
    using s for s.Operator;

    constructor(
        address clfRouter,
        bytes32 clfDonId,
        uint64 clfSubscriptionId,
        uint64 clfDonHostedSecretsVersion,
        uint8 clfDonHostedSecretsSlotId,
        bytes32 requestCLFMessageReportJsCodeHash
    ) FunctionsClient(clfRouter) {
        i_clfDonId = clfDonId;
        i_clfSubscriptionId = clfSubscriptionId;
        i_clfDonHostedSecretsVersion = clfDonHostedSecretsVersion;
        i_clfDonHostedSecretsSlotId = clfDonHostedSecretsSlotId;
        i_requestCLFMessageReportJsCodeHash = requestCLFMessageReportJsCodeHash;
    }

    /* IMMUTABLE VARIABLES */
    bytes32 internal immutable i_requestCLFMessageReportJsCodeHash;
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
        CLFReportType reportType;
        assembly {
            //            reportVersion := byte(1, mload(add(response, 32)))
            reportType := byte(0, mload(add(response, 32)))
        }

        if (reportType == CLFReportType.Message) {
            _handleCLFMessageReport(clfRequestId, response, err);
        } else if (reportType == CLFReportType.OperatorRegistration) {
            _handleCLFOperatorRegistrationReport(clfRequestId, response, err);
        } else if (reportType == CLFReportType.OperatorDeregistration) {
            _handleCLFOperatorDeregistrationReport(clfRequestId, response, err);
        } else {
            emit CLFRequestError(err);
        }
        //        else if (reqType == CLFRequestType.OperatorRegistration) {
        //            _registerOperator();
        //        }

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

        MessageReportResult memory res = DecoderLib._decodeCLFMessageReportResponse(response);
        s.operator().feesEarnedNative[res.operator] += CommonConstants.CLF_REPORT_OPERATOR_FEE;
        _returnCLFRequestDeposit(res.operator);
        emit MessageReport(res.messageId);
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
        //        _returnCLFRequestDeposit(res.operator);
        //        SignerLib._decodeCLFOperatorRegistrationReport(response);
    }

    function _handleCLFOperatorDeregistrationReport(
        bytes32 clfRequestId,
        bytes memory response,
        bytes memory err
    ) internal {
        if (err.length != 0) {
            emit CLFRequestError(err);
            return;
        }
        //        _returnCLFRequestDeposit(res.operator);
        //        SignerLib._decodeCLFOperatorDeregistrationReport(response);
    }

    /* CLF REQUEST FORMATION */
    function _requestMessageReport(
        MessageReportRequest calldata request
    ) internal returns (bytes32 clfRequestId) {
        _witholdCLFRequestDeposit(msg.sender);
        bytes[] memory clfReqArgs = new bytes[](4);
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

    function _requestOperatorRegistration() internal {
        _witholdCLFRequestDeposit(msg.sender);
        emit CLFRequestError("Operator registration is not implemented");
        //        s.verifier().pendingCLFRequests[clfRequestId] = true;
    }

    function _requestOperatorDeregistration() internal {
        _witholdCLFRequestDeposit(msg.sender);
        //        s.verifier().pendingCLFRequests[clfRequestId] = true;
    }

    function _sendCLFRequest(bytes[] memory args) internal returns (bytes32) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(CLF_JS_CODE);
        req.setBytesArgs(args);
        return _sendRequest(req.encodeCBOR(), i_clfSubscriptionId, CLF_GAS_LIMIT, i_clfDonId);
    }

    function _witholdCLFRequestDeposit(address operator) internal {
        require(
            s.operator().deposit[operator] >=
                CommonConstants.OPERATOR_MESSAGE_REPORT_REQUEST_DEPOSIT,
            InsufficientOperatorDeposit()
        );
        s.operator().deposit[operator] -= CommonConstants.OPERATOR_MESSAGE_REPORT_REQUEST_DEPOSIT;
    }

    function _returnCLFRequestDeposit(address operator) internal {
        s.operator().deposit[operator] += CommonConstants.OPERATOR_MESSAGE_REPORT_REQUEST_DEPOSIT;
    }
}
