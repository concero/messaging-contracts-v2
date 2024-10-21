pragma solidity 0.8.28;

import "../Common/Errors.sol";
import "./Errors.sol";
import {IConceroRouter} from "../ConceroRouter/Interfaces/IConceroRouter.sol";
import {CLFRouterStorage} from "./CLFRouterStorage.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {IMessage} from "../Common/IMessage.sol";

contract CLFRouter is IMessage, FunctionsClient, CLFRouterStorage {
    using FunctionsRequest for FunctionsRequest.Request;

    ///////////////////////////
    ////EXTERNAL FUNCTIONS/////
    ///////////////////////////

    enum CLFRequestType {
        RequestCLFMessageReport
    }

    ////////////////////////////
    ///////IMMUTABLE VARS///////
    ////////////////////////////

    address internal immutable i_owner;
    bytes32 internal immutable i_ethersJsCodeHash;
    bytes32 internal immutable i_requestCLFMessageReportJsCodeHash;
    bytes32 internal immutable i_clfDonId;
    uint64 internal immutable i_clfSubscriptionId;
    uint64 internal immutable i_clfDonHostedSecretsVersion;
    uint8 internal immutable i_clfDonHostedSecretsSlotId;

    ////////////////////////////
    ///////CONSTANTS VARS///////
    ////////////////////////////

    string internal constant CLF_JS_CODE =
        "try { const [t, p] = await Promise.all([ fetch('https://raw.githubusercontent.com/ethers-io/ethers.js/v6.10.0/dist/ethers.umd.min.js'), fetch('https://raw.githubusercontent.com/concero/v2-contracts/refs/heads/master/clf/dist/requestReport.min.js'), ]); const [e, c] = await Promise.all([t.text(), p.text()]); const g = async s => { return ( '0x' + Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(s)))) .map(v => ('0' + v.toString(16)).slice(-2).toLowerCase()) .join('') ); }; const r = await g(c); const x = await g(e); const b = bytesArgs[0].toLowerCase(); const o = bytesArgs[1].toLowerCase(); if (r === b && x === o) { const ethers = new Function(e + '; return ethers;')(); return await eval(c); } throw new Error(`${r}!=${b}||${x}!=${o}`); } catch (e) { throw new Error(e.message.slice(0, 255));}";
    uint32 internal constant CLF_GAS_LIMIT = 100_000;

    //////////////////////////
    ///////MODIFIERS//////////
    //////////////////////////

    modifier onlyOwner() {
        require(msg.sender == i_owner, OnlyOwner());
        _;
    }
    modifier onlyOperator() {
        require(s_isAllowedOperator[msg.sender], OnlyAllowedOperator());
        _;
    }

    //////////////////////////
    ///////EVENTS/////////////
    //////////////////////////

    event CLFRequestError(bytes err);
    event CLFMessageReport(bytes32 conceroId);

    //////////////////////////
    ////EXTERNAL FUNCTIONS////
    //////////////////////////

    constructor(
        address functionsRouter,
        bytes32 clfDonId,
        uint64 clfSubscriptionId,
        uint64 clfDonHostedSecretsVersion,
        uint8 clfDonHostedSecretsSlotId,
        bytes32 ethersJsCodeHash,
        bytes32 requestCLFMessageReportJsCodeHash,
        address owner
    ) FunctionsClient(functionsRouter) {
        i_clfDonId = clfDonId;
        i_clfSubscriptionId = clfSubscriptionId;
        i_clfDonHostedSecretsVersion = clfDonHostedSecretsVersion;
        i_clfDonHostedSecretsSlotId = clfDonHostedSecretsSlotId;
        i_ethersJsCodeHash = ethersJsCodeHash;
        i_requestCLFMessageReportJsCodeHash = requestCLFMessageReportJsCodeHash;
        i_owner = owner;
    }

    function requestCLFMessageReport(
        bytes32 messageId,
        Message calldata message
    ) external onlyOperator {
        require(
            s_clfRequestStatusByConceroId[messageId] == CLFRequestStatus.NotStarted,
            MessageAlreadyProcessed()
        );

        bytes[] memory clfReqArgs = new bytes[](4);
        clfReqArgs[0] = abi.encodePacked(i_requestCLFMessageReportJsCodeHash);
        clfReqArgs[1] = abi.encodePacked(i_ethersJsCodeHash);
        clfReqArgs[2] = abi.encodePacked(messageId);
        clfReqArgs[3] = abi.encode(message);

        _prepareAndSendCLFRequest(clfReqArgs);

        s_clfRequestStatusByConceroId[messageId] = CLFRequestStatus.Pending;
    }

    //////////////////////////
    //////ADMIN FUNCTIONS/////
    //////////////////////////

    function registerOperator(address operator) external payable onlyOwner {
        s_isAllowedOperator[operator] = true;
    }

    function deregisterOperator(address operator) external payable onlyOwner {
        s_isAllowedOperator[operator] = false;
    }
    //////////////////////////
    ////INTERNAL FUNCTIONS////
    //////////////////////////

    function fulfillRequest(bytes32, bytes memory response, bytes memory err) internal override {
        if (err.length != 0) {
            emit CLFRequestError(err);
            return;
        }

        CLFRequestType reqType;
        assembly {
            reqType := byte(0, mload(add(response, 0)))
        }

        if (reqType == CLFRequestType.RequestCLFMessageReport) {
            bytes32 conceroId;
            assembly {
                conceroId := mload(add(response, 1))
            }

            s_clfRequestStatusByConceroId[conceroId] = CLFRequestStatus.FulFilled;
            emit CLFMessageReport(conceroId);
        }
    }

    function _prepareAndSendCLFRequest(bytes[] memory args) internal returns (bytes32) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(CLF_JS_CODE);
        req.setBytesArgs(args);
        return _sendRequest(req.encodeCBOR(), i_clfSubscriptionId, CLF_GAS_LIMIT, i_clfDonId);
    }
}
