// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CLFRequestStatus} from "../Interfaces/IConceroVerifier.sol";
import {ConceroVerifierStorage as s} from "./ConceroVerifierStorage.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {IConceroVerifier} from "../Interfaces/IConceroVerifier.sol";
import {InternalMessage} from "../Common/MessageTypes.sol";
import {MessageAlreadyProcessed} from "./Errors.sol";
import {OnlyAllowedOperator} from "../Common/Errors.sol";
import {ConceroOwnable} from "../Common/ConceroOwnable.sol";

contract ConceroVerifier is FunctionsClient, ConceroOwnable {
    using FunctionsRequest for FunctionsRequest.Request;
    using s for s.Router;

    enum CLFRequestType {
        RequestCLFMessageReport
    }

    /* IMMUTABLE VARIABLES */
    bytes32 internal immutable i_ethersJsCodeHash;
    bytes32 internal immutable i_requestCLFMessageReportJsCodeHash;
    bytes32 internal immutable i_clfDonId;
    uint64 internal immutable i_clfSubscriptionId;
    uint64 internal immutable i_clfDonHostedSecretsVersion;
    uint8 internal immutable i_clfDonHostedSecretsSlotId;

    /* CONSTANT VARIABLES */
    string internal constant CLF_JS_CODE =
        "try { const [t, p] = await Promise.all([ fetch('https://raw.githubusercontent.com/ethers-io/ethers.js/v6.10.0/dist/ethers.umd.min.js'), fetch('https://raw.githubusercontent.com/concero/v2-contracts/refs/heads/master/clf/dist/requestReport.min.js'), ]); const [e, c] = await Promise.all([t.text(), p.text()]); const g = async s => { return ( '0x' + Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(s)))) .map(v => ('0' + v.toString(16)).slice(-2).toLowerCase()) .join('') ); }; const r = await g(c); const x = await g(e); const b = bytesArgs[0].toLowerCase(); const o = bytesArgs[1].toLowerCase(); if (r === b && x === o) { const ethers = new Function(e + '; return ethers;')(); return await eval(c); } throw new Error(`${r}!=${b}||${x}!=${o}`); } catch (e) { throw new Error(e.message.slice(0, 255));}";
    uint32 internal constant CLF_GAS_LIMIT = 100_000;

    /* MODIFIERS */
    modifier onlyOperator() {
        require(s.operator().isAllowed[msg.sender], OnlyAllowedOperator());
        _;
    }

    /* EVENTS */
    event CLFRequestError(bytes err);
    event CLFMessageReport(bytes32 indexed conceroId);

    constructor(
        address functionsRouter,
        bytes32 clfDonId,
        uint64 clfSubscriptionId,
        uint64 clfDonHostedSecretsVersion,
        uint8 clfDonHostedSecretsSlotId,
        bytes32 ethersJsCodeHash,
        bytes32 requestCLFMessageReportJsCodeHash
    ) FunctionsClient(functionsRouter) ConceroOwnable() {
        i_clfDonId = clfDonId;
        i_clfSubscriptionId = clfSubscriptionId;
        i_clfDonHostedSecretsVersion = clfDonHostedSecretsVersion;
        i_clfDonHostedSecretsSlotId = clfDonHostedSecretsSlotId;
        i_ethersJsCodeHash = ethersJsCodeHash;
        i_requestCLFMessageReportJsCodeHash = requestCLFMessageReportJsCodeHash;
    }

    function requestCLFMessageReport(
        bytes32 messageId,
        InternalMessage calldata message
    ) external onlyOperator {
        require(
            !s.router().pendingMessageReports[messageId],
            MessageAlreadyProcessed()
        );

        bytes[] memory clfReqArgs = new bytes[](4);
        clfReqArgs[0] = abi.encodePacked(i_requestCLFMessageReportJsCodeHash);
        clfReqArgs[1] = abi.encodePacked(i_ethersJsCodeHash);
        clfReqArgs[2] = abi.encodePacked(messageId);
        clfReqArgs[3] = abi.encode(message);

        bytes32 clfRequestId = _sendCLFRequest(clfReqArgs);
        s.router().pendingCLFRequests[clfRequestId] = true;
        s.router().pendingMessageReports[messageId] = true;
    }

    /* OWNER FUNCTIONS */

    /* INTERNAL FUNCTIONS */
    function _registerOperator(address operator) internal {
        // Step 1: Check if OP is registered with symbiotic and has enough delegated Stake
        s.operator().isAllowed[operator] = true;
    }

    function _deregisterOperator(address operator) internal {
        s.operator().isAllowed[operator] = false;
    }

    function fulfillRequest(bytes32 clfRequestId, bytes memory response, bytes memory err) internal override {
        if (err.length != 0) {
            emit CLFRequestError(err);
            return;
        }

        CLFRequestType reqType;
        assembly {
            reqType := byte(0, mload(add(response, 32)))
        }

        if (reqType == CLFRequestType.RequestCLFMessageReport) {
            bytes32 messageId;
            assembly {
                messageId := mload(add(response, 33))
            }

            delete s.router().pendingMessageReports[messageId];
        }
//        else if (reqType == CLFRequestType.OperatorRegistration) {
//            _registerOperator();
//        }

       delete s.router().pendingCLFRequests[clfRequestId];
    }

    function _sendCLFRequest(bytes[] memory args) internal returns (bytes32) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(CLF_JS_CODE);
        req.setBytesArgs(args);
        return _sendRequest(req.encodeCBOR(), i_clfSubscriptionId, CLF_GAS_LIMIT, i_clfDonId);
    }
}
