pragma solidity 0.8.20;

import "./Errors.sol";
import {IConceroRouter} from "./Interfaces/IConceroRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ConceroRouterStorage} from "./ConceroRouterStorage.sol";
import "./Constants.sol";

contract ConceroRouter is IConceroRouter, ConceroRouterStorage {
    using SafeERC20 for IERC20;

    /*IMMUTABLE VARIABLES*/

    address internal immutable i_USDC;
    address internal immutable i_clfDonSigner_0;
    address internal immutable i_clfDonSigner_1;
    address internal immutable i_clfDonSigner_2;

    constructor(
        address usdc,
        address clfDonSigner_0,
        address clfDonSigner_1,
        address clfDonSigner_2
    ) {
        i_USDC = usdc;
        i_clfDonSigner_0 = clfDonSigner_0;
        i_clfDonSigner_1 = clfDonSigner_1;
        i_clfDonSigner_2 = clfDonSigner_2;
    }

    function sendMessage(MessageRequest calldata req) external payable {
        // step 1: validate the message (fee tokens, receiver)
        // TODO: mb validate data and extraArgs
        uint256 fee = getFee(req);

        //step 2: get fees from the user
        if (req.feeToken == i_USDC) {
            IERC20(i_USDC).safeTransferFrom(msg.sender, address(this), fee);
        }

        //step 3: TODO: transfer token amounts if exists

        //step 4: emit the message
        // TODO: add custom nonce to id generation
        bytes32 messageId = keccak256(
            abi.encode(req.message, block.number, block.prevrandao, msg.sender)
        );

        emit ConceroMessage(messageId, req.message);
    }

    /**
     * @notice Submits a message report, verifies the signatures, and processes the report data.
     * @param reportContext Report context containing config digest, epoch, and extra hash.
     * @param report Serialized report data.
     * @param rs Array of R components of the signatures.
     * @param ss Array of S components of the signatures.
     * @param rawVs Concatenated V components of the signatures.
     */
    function submitMessageReport(
        bytes32[3] calldata reportContext,
        bytes calldata report,
        bytes32[] calldata rs,
        bytes32[] calldata ss,
        bytes calldata rawVs
    ) external {
        // Step 1: Recompute the hash
        bytes32 h = _computeReportHash(reportContext, report);

        // Step 2: Recover and verify the signatures
        _verifyClfReportSignatures(h, rs, ss, rawVs);

        // Step 3: Decode and process the report data
        _processClfReport(report);
        //TODO: further actions with report: operator reward, passing the TX to user etc
    }

    //////////////////////////////////
    ////////INTERNAL FUNCTIONS////////
    //////////////////////////////////

    /**
     * @notice Computes the hash of the report and report context.
     * @param reportContext The context of the report.
     * @param report The serialized report data.
     * @return The computed hash of the report.
     */
    function _computeReportHash(
        bytes32[3] calldata reportContext,
        bytes calldata report
    ) internal pure returns (bytes32) {
        bytes32 reportHash = keccak256(report);
        bytes memory messageToHash = abi.encodePacked(
            reportHash,
            reportContext[0],
            reportContext[1],
            reportContext[2]
        );
        return keccak256(messageToHash);
    }

    function getFee(MessageRequest calldata req) public view returns (uint256) {
        _validateFeeToken(req.feeToken);
        _validateDstChainSelector(req.message.dstChainSelector);

        // TODO: add fee calculation logic
        return 50_000; // fee in usdc
    }

    function isChainSupported(uint64 chainSelector) external view returns (bool) {
        return _isChainSupported(chainSelector);
    }

    //////////////////////////////////
    ////////INTERNAL FUNCTIONS////////
    //////////////////////////////////

    /**
     * @notice Verifies the signatures of the report.
     * @param h The computed hash of the report.
     * @param rs Array of R components of the signatures.
     * @param ss Array of S components of the signatures.
     * @param rawVs Concatenated V components of the signatures.
     */
    function _verifyClfReportSignatures(
        bytes32 h,
        bytes32[] calldata rs,
        bytes32[] calldata ss,
        bytes calldata rawVs
    ) internal view {
        uint256 numSignatures = rs.length;

        if (numSignatures != ss.length || numSignatures != rawVs.length) {
            revert("Mismatched signature arrays");
        }

        uint256 expectedNumSignatures = 3; // Adjust according to your requirements

        if (numSignatures != expectedNumSignatures) {
            revert("Incorrect number of signatures");
        }

        address[] memory signers = new address[](numSignatures);

        for (uint256 i = 0; i < numSignatures; i++) {
            uint8 v = uint8(rawVs[i]) + 27; // rawVs contains values 0 or 1, add 27 to get 27 or 28
            bytes32 r = rs[i];
            bytes32 s = ss[i];

            // Recover the signer's address
            address signer = ecrecover(h, v, r, s);

            if (signer == address(0)) {
                revert("Invalid signature");
            }

            // Check for duplicate signatures
            for (uint256 j = 0; j < i; j++) {
                if (signers[j] == signer) {
                    revert("Duplicate signature detected");
                }
            }

            // Verify that the signer is authorized
            if (!_isAuthorizedClfDonSigner(signer)) {
                revert("Unauthorized signer");
            }

            signers[i] = signer;
        }
    }

    /**
     * @notice Decodes the report data and processes it.
     * @param report The serialized report data.
     */
    function _processClfReport(bytes calldata report) internal {
        (
            bytes32[] memory requestIds,
            bytes[] memory results,
            bytes[] memory errors,
            bytes[] memory onchainMetadata,
            bytes[] memory offchainMetadata
        ) = abi.decode(report, (bytes32[], bytes[], bytes[], bytes[], bytes[]));

        uint256 numberOfFulfillments = requestIds.length;

        for (uint256 i = 0; i < numberOfFulfillments; i++) {
            bytes32 requestId = requestIds[i];
            bytes memory result = results[i];
            bytes memory error = errors[i];
            bytes memory metadata = onchainMetadata[i];
            bytes memory offchainMeta = offchainMetadata[i];

            emit ReportProcessed(requestId, result, error, metadata, offchainMeta);
        }
    }

    function _isAuthorizedClfDonSigner(address clfDonSigner) internal view returns (bool) {
        return (clfDonSigner == i_clfDonSigner_0 ||
            clfDonSigner == i_clfDonSigner_1 ||
            clfDonSigner == i_clfDonSigner_2);
    }

    function _validateFeeToken(address feeToken) internal view {
        // add this line in future: && feeToken != address(0)

        if (feeToken != i_USDC) {
            revert UnsupportedFeeToken();
        }
    }

    function _validateDstChainSelector(uint64 dstChainSelector) internal view {
        if (!_isChainSupported(dstChainSelector)) {
            revert UnsupportedDstChain();
        }
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
