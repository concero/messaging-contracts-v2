// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {EcdsaValidatorLib} from "./EcdsaValidatorLib.sol";
import {IConceroRouter} from "../../interfaces/IConceroRouter.sol";
import {CommonErrors} from "../../common/CommonErrors.sol";
import {ValidatorCodec} from "../../common/libraries/ValidatorCodec.sol";

/// @title CreValidatorLib
/// @notice ECDSA-based validator library for Concero that validates Chainlink CRE-like reports.
/// @dev
/// - Extends {EcdsaValidatorLib} to:
///   * enforce a whitelist of allowed workflow IDs,
///   * check that the report commits to the exact Concero `messageReceipt`,
///   * provide zero-fee validation with EVM config from {EcdsaValidatorLib}.
/// - Validation flow:
///   1. `_verifySignatures` (from `EcdsaValidatorLib`) ensures enough distinct allowed signers.
///   2. `_checkValidation`:
///      - ensures `workflow_execution_id` is allowed,
///      - ensures the report’s embedded message hash equals `keccak256(messageReceipt)`.
contract CreValidatorLib is AccessControlUpgradeable, EcdsaValidatorLib {
    /// @notice Thrown when a report contains a workflow ID that is not on the allowlist.
    /// @param receivedWorkflowId Workflow ID extracted from the report.
    error InvalidCreWorkflowId(bytes32 receivedWorkflowId);

    /// @notice Thrown when a provided Merkle proof is invalid or does not match the expected Merkle root.
    /// @param merkleRoot Merkle root against which the proof was verified.
    /// @param leaf Leaf value that was proven to be part of the Merkle tree.
    error InvalidMerkleProof(bytes32 merkleRoot, bytes32 leaf);

    bytes32 internal constant ADMIN = keccak256("ADMIN");

    uint8 internal constant RAW_REPORT_METADATA_LENGTH = 109;
    uint8 internal constant RAW_REPORT_LENGTH = 141;
    uint8 internal constant REPORT_CONTEXT_LENGTH = 96;
    uint16 internal constant SIGNATURES_OFFSET = RAW_REPORT_LENGTH + REPORT_CONTEXT_LENGTH;

    mapping(bytes32 workflowId => bool isAllowed) internal s_isCreWorkflowIdAllowed;

    constructor() AccessControlUpgradeable() EcdsaValidatorLib() {}

    // -------------------------------------------------------------------------
    // Validation data format (high-level)
    // -------------------------------------------------------------------------
    // We expect: bytes calldata validation = abi.encodePacked(
    //     rawReport,          // RAW_REPORT_LENGTH bytes
    //     reportContext,      // REPORT_CONTEXT_LENGTH bytes
    //     abi.encode(signatures) // abi-encoded bytes[] signatures
    // );
    //
    // rawReport layout (first 32 bytes of memory contain length of rawReport):
    // version                  // offset  32, size  1
    // workflow_execution_id    // offset  33, size 32
    // timestamp                // offset  65, size  4
    // don_id                   // offset  69, size  4
    // don_config_version       // offset  73, size  4
    // workflow_cid             // offset  77, size 32
    // workflow_name            // offset 109, size 10
    // workflow_owner           // offset 119, size 20
    // report_id                // offset 139, size  2
    //
    // We additionally expect a Merkle root to be embedded between
    // RAW_REPORT_METADATA_LENGTH and RAW_REPORT_LENGTH in `validation`.
    // This Merkle root commits to a tree that includes the Concero message hash.

    // VIEW FUNCTIONS

    /// @notice Returns the fee for this validator library (always zero).
    /// @dev
    /// - CRE-based validation is treated as zero-cost here;
    ///   only relayer fees are expected to be paid.
    /// - Kept for compatibility with the `IValidatorLib` fee API.
    /// - MUST revert with `FeeTokenNotSupported` if the fee token is not supported.
    /// @dev messageRequest Unused; present to match the interface shape.
    /// @return Always returns 0.
    function getFee(
        IConceroRouter.MessageRequest calldata messageRequest
    ) public pure returns (uint256) {
        require(
            isFeeTokenSupported(messageRequest.feeToken),
            CommonErrors.FeeTokenNotSupported(messageRequest.feeToken)
        );
        return 0;
    }

    /// @dev
    /// - Returns `(0, validatorConfig)`:
    ///   * zero fee,
    ///   * EVM validator config (gas limit) from {EcdsaValidatorLib.getValidatorConfig}.
    /// @param messageRequest Message request used to derive validator config (per dst chain).
    /// @return fee Always 0.
    /// @return validatorConfig Encoded EVM validator config for this validator.
    function getFeeAndValidatorConfig(
        IConceroRouter.MessageRequest calldata messageRequest
    ) external view returns (uint256, bytes memory) {
        return (getFee(messageRequest), getValidatorConfig(messageRequest));
    }

    /// @notice Returns whether a given CRE workflow ID is allowed.
    /// @param workflowId Workflow ID to check.
    /// @return True if the workflow ID is on the allowlist, false otherwise.
    function isWorkflowIdAllowed(bytes32 workflowId) external view returns (bool) {
        return s_isCreWorkflowIdAllowed[workflowId];
    }

    /// @dev
    /// - This validator only supports native token (address(0)) as fee token.
    /// @param feeToken Address of the fee token (use address(0) for native).
    /// @return True if `feeToken` is the native token, false otherwise.
    function isFeeTokenSupported(address feeToken) public pure returns (bool) {
        return feeToken == address(0);
    }

    // INITIALIZER

    function initialize(address admin) public initializer {
        _setRoleAdmin(ADMIN, DEFAULT_ADMIN_ROLE);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN, admin);
    }

    // ADMIN FUNCTIONS

    /// @notice Sets or unsets allowed ECDSA signers in batch.
    /// @dev
    /// - Callable only by accounts with `ADMIN` role.
    /// - Delegates to `_setAllowedSigners` in {EcdsaValidatorLib}.
    /// @param signers Array of signer addresses.
    /// @param isAllowedArr Array of flags indicating whether each signer is allowed.
    function setAllowedSigners(
        address[] calldata signers,
        bool[] calldata isAllowedArr
    ) external onlyRole(ADMIN) {
        _setAllowedSigners(signers, isAllowedArr);
    }

    /// @notice Sets the minimum required number of signatures for validation.
    /// @dev
    /// - Callable only by accounts with `ADMIN` role.
    /// - Delegates to `_setMinSignersCount` in {EcdsaValidatorLib}.
    /// @param expectedSignersCount New minimum number of required signers.
    function setMinSignersCount(uint8 expectedSignersCount) external onlyRole(ADMIN) {
        _setMinSignersCount(expectedSignersCount);
    }

    /// @notice Adds or removes a CRE workflow ID from the allowlist.
    /// @dev
    /// - Callable only by accounts with `ADMIN` role.
    /// @param id Workflow ID to update.
    /// @param isAllowed `true` to allow, `false` to disallow.
    function setIsWorkflowIdAllowed(bytes32 id, bool isAllowed) external onlyRole(ADMIN) {
        s_isCreWorkflowIdAllowed[id] = isAllowed;
    }

    /// @notice Sets per-chain gas limits used in the EVM validator config.
    /// @dev
    /// - Callable only by accounts with `ADMIN` role.
    /// - Delegates to `_setDstChainGasLimits` in {EcdsaValidatorLib}.
    /// @param dstChainSelectors Destination chain selectors to configure.
    /// @param gasLimits Gas limits corresponding to each destination chain.
    function setDstChainGasLimits(
        uint24[] calldata dstChainSelectors,
        uint32[] calldata gasLimits
    ) external onlyRole(ADMIN) {
        _setDstChainGasLimits(dstChainSelectors, gasLimits);
    }

    // INTERNAL FUNCTIONS

    /// @notice Extracts signatures and the signed Merkle root hash from the CRE validation blob.
    /// @dev
    /// - Expects:
    ///   `validation = abi.encodePacked(rawReport, reportContext, abi.encode(signatures, proof))`
    /// - Returns:
    ///   * `signatures` decoded from `validation[SIGNATURES_OFFSET:]`,
    ///   * `hash` = keccak256( keccak256(rawReport) || reportContext ).
    /// @param validation Validation blob containing raw report, context and signatures.
    /// @return sigs Array of extracted signatures.
    /// @return hash Message hash to be used for ECDSA recovery.
    function _extractSignaturesAndHash(
        bytes calldata validation
    ) internal pure override returns (bytes[] memory sigs, bytes32) {
        (sigs, ) = abi.decode(validation[SIGNATURES_OFFSET:], (bytes[], bytes32[]));

        return (
            sigs,
            keccak256(
                abi.encodePacked(
                    keccak256(validation[:RAW_REPORT_LENGTH]),
                    validation[RAW_REPORT_LENGTH:SIGNATURES_OFFSET]
                )
            )
        );
    }

    /// @notice Performs additional CRE-specific validation logic.
    /// @dev
    /// - Steps:
    ///   1. Extract `workflow_execution_id` from the `rawReport` and ensure it is allowlisted.
    ///   2. Extract the Merkle root embedded in `validation`.
    ///   3. Verify, using the provided Merkle proof, that messageReceipt) hash
    ///      is included in the Merkle tree committed to by the extracted Merkle root.
    ///
    /// @param messageReceipt Packed Concero message receipt.
    /// @param validation Validation blob containing the CRE report, Merkle root,
    ///        and a Merkle proof of inclusion.
    /// @return Always returns true if no validation check fails.
    function _checkValidation(
        bytes calldata messageReceipt,
        bytes calldata validation
    ) internal view override returns (bool) {
        bytes memory rawReport = validation[:RAW_REPORT_LENGTH];
        bytes32 workflowId;
        assembly {
            workflowId := mload(add(rawReport, 77))
        }

        require(s_isCreWorkflowIdAllowed[workflowId], InvalidCreWorkflowId(workflowId));

        (, bytes32[] memory proof) = abi.decode(
            validation[SIGNATURES_OFFSET:],
            (bytes[], bytes32[])
        );

        bytes32 merkleRoot = bytes32(validation[RAW_REPORT_METADATA_LENGTH:RAW_REPORT_LENGTH]);
        bytes32 leaf = keccak256(messageReceipt);

        require(MerkleProof.verify(proof, merkleRoot, leaf), InvalidMerkleProof(merkleRoot, leaf));

        return true;
    }
}
