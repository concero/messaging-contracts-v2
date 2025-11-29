// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {EcdsaValidatorLib} from "./EcdsaValidatorLib.sol";
import {IConceroRouter} from "../../interfaces/IConceroRouter.sol";

contract CreValidatorLib is AccessControlUpgradeable, EcdsaValidatorLib {
    error InvalidCreWorkflowId(bytes32 receivedWorkflowId);
    error MessageReceiptHashMismatch(
        bytes32 messageReceiptHash,
        bytes32 validationMessageReceiptHash
    );

    bytes32 internal constant ADMIN = keccak256("ADMIN");

    uint8 internal constant RAW_REPORT_METADATA_LENGTH = 109;
    uint8 internal constant RAW_REPORT_LENGTH = 141;
    uint8 internal constant REPORT_CONTEXT_LENGTH = 96;
    uint16 internal constant SIGNATURES_OFFSET = RAW_REPORT_LENGTH + REPORT_CONTEXT_LENGTH;

    mapping(bytes32 workflowId => bool isAllowed) internal s_isCreWorkflowIdAllowed;

    constructor() AccessControlUpgradeable() EcdsaValidatorLib() {}

    // @dev we expect bytes calldata validation = abi.encodePacked(rawReport, reportContext, abi.encode(signatures));
    // @dev (first 32 bytes of memory contain length of the rawReport)
    // version                  // offset  32, size  1
    // workflow_execution_id    // offset  33, size 32
    // timestamp                // offset  65, size  4
    // don_id                   // offset  69, size  4
    // don_config_version,	    // offset  73, size  4
    // workflow_cid             // offset  77, size 32
    // workflow_name            // offset 109, size 10
    // workflow_owner           // offset 119, size 20
    // report_id              // offset 139, size  2

    // VIEW FUNCTIONS

    function getFee(IConceroRouter.MessageRequest calldata) external pure returns (uint256) {
        return 0;
    }

    function isWorkflowIdAllowed(bytes32 workflowId) external view returns (bool) {
        return s_isCreWorkflowIdAllowed[workflowId];
    }

    // INITIALIZER

    function initialize(address admin) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN, admin);
    }

    // ADMIN FUNCTIONS

    function setAllowedSigners(
        address[] calldata signers,
        bool[] calldata isAllowedArr
    ) external onlyRole(ADMIN) {
        _setAllowedSigners(signers, isAllowedArr);
    }

    function setMinSignersCount(uint8 expectedSignersCount) external onlyRole(ADMIN) {
        _setMinSignersCount(expectedSignersCount);
    }

    function setIsWorkflowIdAllowed(bytes32 id, bool isAllowed) external onlyRole(ADMIN) {
        s_isCreWorkflowIdAllowed[id] = isAllowed;
    }

    // INTERNAL FUNCTIONS

    function _extractSignaturesAndHash(
        bytes calldata validation
    ) internal pure override returns (bytes[] memory, bytes32) {
        return (
            abi.decode(validation[SIGNATURES_OFFSET:], (bytes[])),
            keccak256(
                abi.encodePacked(
                    keccak256(validation[:RAW_REPORT_LENGTH]),
                    validation[RAW_REPORT_LENGTH:SIGNATURES_OFFSET]
                )
            )
        );
    }

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

        bytes32 messageReceiptHash = keccak256(messageReceipt);
        bytes32 validationMessageReceiptHash = bytes32(
            validation[RAW_REPORT_METADATA_LENGTH:RAW_REPORT_LENGTH]
        );

        require(
            messageReceiptHash == validationMessageReceiptHash,
            MessageReceiptHashMismatch(messageReceiptHash, validationMessageReceiptHash)
        );

        return true;
    }
}
