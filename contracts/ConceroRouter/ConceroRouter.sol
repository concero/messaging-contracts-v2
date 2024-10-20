pragma solidity 0.8.28;

import "../Common/Errors.sol";
import "./Constants.sol";
import "./Errors.sol";
import {IConceroMessageClient} from "./Interfaces/IConceroMessageClient.sol";
import {ConceroRouterStorage} from "./ConceroRouterStorage.sol";
import {IConceroRouter} from "./Interfaces/IConceroRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ConceroRouter is IConceroRouter, ConceroRouterStorage {
    using SafeERC20 for IERC20;

    /* CONSTANTS */
    uint16 internal CONCERO_VALUE_TRANSFER_FEE_FACTOR = 1_000;

    /*IMMUTABLE VARIABLES*/
    address internal immutable i_owner;
    address internal immutable i_USDC;
    uint64 internal immutable i_chainSelector;
    address internal immutable i_clfDonSigner_0;
    address internal immutable i_clfDonSigner_1;
    address internal immutable i_clfDonSigner_2;
    address internal immutable i_clfDonSigner_3;

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

    constructor(
        address usdc,
        uint64 chainSelector,
        address _owner,
        address clfDonSigner_0,
        address clfDonSigner_1,
        address clfDonSigner_2,
        address clfDonSigner_3
    ) {
        i_USDC = usdc;
        i_chainSelector = chainSelector;
        i_owner = _owner;
        i_clfDonSigner_0 = clfDonSigner_0;
        i_clfDonSigner_1 = clfDonSigner_1;
        i_clfDonSigner_2 = clfDonSigner_2;
        i_clfDonSigner_3 = clfDonSigner_3;
    }

    function sendMessage(MessageRequest calldata req) external payable {
        // step 1: validate the message (fee tokens, receiver)
        // TODO: mb validate data and extraArgs
        _collectMessageFee(req);

        //step 3: TODO: transfer token amounts if exists

        Message memory message = _buildMessage(req);

        //step 4: emit the message
        // TODO: add custom nonce to id generation
        bytes32 messageId = keccak256(abi.encode(message, block.number, msg.sender));

        emit ConceroMessageSent(messageId, message);
    }

    /**
     * @notice Submits a message report, verifies the signatures, and processes the report data.
     * @param reportSubmission the serialized report data.
     * @param message the message data.
     */
    function submitMessageReport(
        ClfDonReportSubmission calldata reportSubmission,
        Message calldata message
    ) external onlyOperator {
        // Step 1: Recover and verify the signatures
        _verifyClfReportSignatures(reportSubmission);

        // Step 2: Decode and process the report data
        (bytes32 messageId, bytes32 messageHash) = _extractClfResponse(reportSubmission.report);

        // Step 3: validate the message
        _validateMessage(message, messageId, messageHash);

        // Step 4: process message
        _processMessage(messageId, message);
    }

    function getMessageFee(MessageRequest calldata message) public view returns (uint256) {
        uint256 valueTransferFee = 0;

        for (uint256 i = 0; i < message.tokenAmounts.length; i++) {
            valueTransferFee += message.tokenAmounts[i].amount / CONCERO_VALUE_TRANSFER_FEE_FACTOR;
        }

        if (message.feeToken == address(0)) {
            return 50_000 + valueTransferFee;
        } else if (message.feeToken == i_USDC) {
            return 50_000 + valueTransferFee;
        } else {
            revert UnsupportedFeeToken();
        }
    }

    function isChainSupported(uint64 chainSelector) external view returns (bool) {
        return _isChainSupported(chainSelector);
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

    //////////////////////////////////
    ////////INTERNAL FUNCTIONS////////
    //////////////////////////////////

    function _processMessage(bytes32 messageId, Message calldata message) internal {
        // TODO: add operator rewards logic here
        // add value transfer logic in the future here

        EVMArgs memory args = abi.decode(message.extraArgs, (EVMArgs));

        (bool success, bytes memory data) = message.receiver.call{gas: args.gasLimit}(
            abi.encodeWithSelector(
                IConceroMessageClient.conceroMessageReceive.selector,
                messageId,
                message.data
            )
        );

        require(success, MessageProcessingFailed(data));

        emit ConceroMessageReceived(messageId, message);
    }

    function _validateMessage(
        Message calldata message,
        bytes32 messageId,
        bytes32 reportMessageHash
    ) internal pure {
        bytes32 messageHash = keccak256(abi.encode(messageId, message));
        require(messageHash == reportMessageHash, InvalidMessageHash());
    }

    function _collectMessageFee(MessageRequest calldata message) internal {
        uint256 feePayable = getMessageFee(message);

        if (message.feeToken == i_USDC) {
            IERC20(i_USDC).safeTransferFrom(msg.sender, address(this), feePayable);
        } else if (message.feeToken == address(0)) {
            require(msg.value == feePayable, InsufficientFee());
        }
    }

    function _buildMessage(MessageRequest calldata req) internal view returns (Message memory) {
        return
            Message({
                srcChainSelector: i_chainSelector,
                dstChainSelector: req.dstChainSelector,
                receiver: req.receiver,
                sender: msg.sender,
                tokenAmounts: req.tokenAmounts,
                relayers: req.relayers,
                data: req.data,
                extraArgs: req.extraArgs
            });
    }

    /**
     * @notice Computes the hash of the report and report context.
     * @param reportContext The context of the report.
     * @param report The serialized report data.
     * @return The computed hash of the report.
     */
    function _computeCLFReportHash(
        bytes32[3] calldata reportContext,
        bytes calldata report
    ) internal pure returns (bytes32) {
        bytes32 reportHash = keccak256(report);
        bytes memory messageToHash = abi.encodePacked(reportHash, reportContext);
        return keccak256(messageToHash);
    }

    /**
     * @notice Verifies the signatures of the report.
     * @param reportSubmission The report submission data.
     */
    function _verifyClfReportSignatures(
        ClfDonReportSubmission calldata reportSubmission
    ) internal view {
        bytes32 h = _computeCLFReportHash(reportSubmission.context, reportSubmission.report);
        bytes32[] memory rs = reportSubmission.rs;
        bytes32[] memory ss = reportSubmission.ss;
        bytes memory rawVs = reportSubmission.rawVs;

        uint256 expectedNumSignatures = 3;

        require(
            rs.length == ss.length && rs.length == expectedNumSignatures,
            IncorrectNumberOfSignatures()
        );

        address[] memory signers = new address[](rs.length);

        for (uint256 i = 0; i < rs.length; i++) {
            uint8 v = uint8(rawVs[i]) + 27; // rawVs contains values 0 or 1, add 27 to get 27 or 28
            bytes32 r = rs[i];
            bytes32 s = ss[i];

            address signer = ecrecover(h, v, r, s);
            require(_isAuthorizedClfDonSigner(signer), UnauthorizedSigner(signer));

            for (uint256 j = 0; j < i; j++) {
                require(signers[j] != signer, DuplicateSignatureDetected(signer));
            }

            signers[i] = signer;
        }
    }

    function _extractClfResponse(bytes calldata report) internal pure returns (bytes32, bytes32) {
        (, bytes[] memory results, , , ) = abi.decode(
            report,
            (bytes32[], bytes[], bytes[], bytes[], bytes[])
        );

        bytes32 messageId;
        bytes32 messageHash;
        assembly {
            messageId := mload(add(results, 33))
            messageHash := mload(add(results, 65))
        }

        return (messageId, messageHash);
    }

    function _isAuthorizedClfDonSigner(address clfDonSigner) internal view returns (bool) {
        if (clfDonSigner == address(0)) {
            return false;
        }

        return (clfDonSigner == i_clfDonSigner_0 ||
            clfDonSigner == i_clfDonSigner_1 ||
            clfDonSigner == i_clfDonSigner_2 ||
            clfDonSigner == i_clfDonSigner_3);
    }

    function _isChainSupported(uint64 chainSelector) internal view returns (bool) {
        if (_isMainnet()) {
            return _isMainnetChainSupported(chainSelector);
        } else {
            return _isTestnetChainSupported(chainSelector);
        }
    }

    function _isTestnetChainSupported(uint64 chainSelector) internal pure returns (bool) {
        if (
            chainSelector == CHAIN_SELECTOR_ARBITRUM_SEPOLIA ||
            chainSelector == CHAIN_SELECTOR_BASE_SEPOLIA ||
            chainSelector == CHAIN_SELECTOR_OPTIMISM_SEPOLIA ||
            chainSelector == CHAIN_SELECTOR_POLYGON_AMOY
        ) {
            return true;
        }
        return false;
    }

    function _isMainnetChainSupported(uint64 chainSelector) internal pure returns (bool) {
        if (
            chainSelector == CHAIN_SELECTOR_ARBITRUM ||
            chainSelector == CHAIN_SELECTOR_BASE ||
            chainSelector == CHAIN_SELECTOR_POLYGON ||
            chainSelector == CHAIN_SELECTOR_AVALANCHE ||
            chainSelector == CHAIN_SELECTOR_OPTIMISM
        ) {
            return true;
        }
        return false;
    }

    function _isMainnet() internal view returns (bool) {
        uint256 chainId = block.chainid;

        if (
            chainId == CHAIN_ID_ETHEREUM ||
            chainId == CHAIN_ID_BASE ||
            chainId == CHAIN_ID_AVALANCHE ||
            chainId == CHAIN_ID_ARBITRUM ||
            chainId == CHAIN_ID_POLYGON
        ) {
            return true;
        }
        return false;
    }
}
