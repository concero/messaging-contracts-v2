pragma solidity 0.8.20;

import {IConceroMessenger} from "../Messenger/Interfaces/IConceroMessenger.sol";
import {MasterChainCLFStorage} from "./MasterChainCLFStorage.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import "../Common/Errors.sol";
import "./Errors.sol";

contract MasterChainCLF is FunctionsClient, MasterChainCLFStorage {
    using FunctionsRequest for FunctionsRequest.Request;

    ///////////////////////////
    ////EXTERNAL FUNCTIONS/////
    ///////////////////////////

    struct Message {
        bytes32 id;
        uint64 dstChainSelector;
        uint64 srcChainSelector;
        uint64 srcChainBlockNumber;
        address receiver;
        IConceroMessenger.TokenAmount[] tokenAmounts;
        IConceroMessenger.Relayer[] relayers;
        bytes data;
        bytes extraArgs;
    }

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
        "function requestCLFMessageReport(clfDonId, clfSubscriptionId, clfDonHostedSecretsVersion, clfDonHostedSecretsSlotId, ethersJsCodeHash, requestCLFMessageReportJsCodeHash, clfArgs) { return requestCLFMessageReport(clfDonId, clfSubscriptionId, clfDonHostedSecretsVersion, clfDonHostedSecretsSlotId, ethersJsCodeHash, requestCLFMessageReportJsCodeHash, clfArgs); }";
    uint32 internal constant CLF_GAS_LIMIT = 100_000;

    //////////////////////////
    ///////MODIFIERS//////////
    //////////////////////////

    modifier onlyAllowedOperator() {
        _onlyAllowedOperator();
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert OnlyOwner();
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
        bytes32 requestCLFMessageReportJsCodeHash
    ) FunctionsClient(functionsRouter) {
        i_owner = msg.sender;
        i_clfDonId = clfDonId;
        i_clfSubscriptionId = clfSubscriptionId;
        i_clfDonHostedSecretsVersion = clfDonHostedSecretsVersion;
        i_clfDonHostedSecretsSlotId = clfDonHostedSecretsSlotId;
        i_ethersJsCodeHash = ethersJsCodeHash;
        i_requestCLFMessageReportJsCodeHash = requestCLFMessageReportJsCodeHash;
    }

    function requestCLFMessageReport(Message calldata message) external onlyAllowedOperator {
        if (s_clfRequestStatusByConceroId[message.id] != CLFRequestStatus.NotStarted) {
            revert MessageAlreadyProcessed();
        }

        bytes[] memory clfReqArgs = new bytes[](3);
        clfReqArgs[0] = abi.encodePacked(i_ethersJsCodeHash);
        clfReqArgs[1] = abi.encodePacked(i_requestCLFMessageReportJsCodeHash);
        clfReqArgs[2] = abi.encodePacked(abi.encode(message));

        _prepareAndSendCLFRequest(clfReqArgs);

        s_clfRequestStatusByConceroId[message.id] = CLFRequestStatus.Pending;
    }

    //////////////////////////
    //////ADMIN FUNCTIONS/////
    //////////////////////////

    function addAllowedOperator(address _operator) external payable onlyOwner {
        s_isAllowedOperators[_operator] = true;
    }

    function removeAllowedOperator(address _operator) external payable onlyOwner {
        s_isAllowedOperators[_operator] = false;
    }

    //////////////////////////
    ////INTERNAL FUNCTIONS////
    //////////////////////////

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (err.length != 0) {
            emit CLFRequestError(err);
            return;
        }

        (CLFRequestType reqType, bytes memory clfRes) = abi.decode(
            response,
            (CLFRequestType, bytes)
        );

        if (reqType == CLFRequestType.RequestCLFMessageReport) {
            _fulfillRequestCLFMessageReport(clfRes);
        }
    }

    function _fulfillRequestCLFMessageReport(bytes memory clfRes) internal {
        (bytes32 conceroId, ) = abi.decode(clfRes, (bytes32, bytes32));
        s_clfRequestStatusByConceroId[conceroId] = CLFRequestStatus.FulFilled;
        emit CLFMessageReport(conceroId);
    }

    function _prepareAndSendCLFRequest(bytes[] memory args) internal returns (bytes32) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(CLF_JS_CODE);
        req.addDONHostedSecrets(i_clfDonHostedSecretsSlotId, i_clfDonHostedSecretsVersion);
        req.setBytesArgs(args);
        return _sendRequest(req.encodeCBOR(), i_clfSubscriptionId, CLF_GAS_LIMIT, i_clfDonId);
    }

    function _onlyAllowedOperator() internal {
        if (!s_isAllowedOperators[msg.sender]) revert OnlyAllowedOperator();
    }
}
