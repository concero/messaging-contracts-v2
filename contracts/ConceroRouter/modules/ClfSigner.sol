//SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Base} from "./Base.sol";
import {Types} from "../libraries/Types.sol";

abstract contract ClfSigner is Base {
    error IncorrectNumberOfSignatures();
    error UnauthorizedSigner(address signer);
    error DuplicateSignatureDetected(address signer);
    error InvalidClfReportClient();
    error InvalidClfReportSubscriptionId();

    address internal immutable i_clfSigner0;
    address internal immutable i_clfSigner1;
    address internal immutable i_clfSigner2;
    address internal immutable i_clfSigner3;

    address internal immutable i_conceroVerifier;
    uint64 internal immutable i_conceroVerifierSubId;

    constructor(
        address conceroVerifier,
        uint64 conceroVerifierSubId,
        address[4] memory clfSigners
    ) {
        i_clfSigner0 = clfSigners[0];
        i_clfSigner1 = clfSigners[1];
        i_clfSigner2 = clfSigners[2];
        i_clfSigner3 = clfSigners[3];
        i_conceroVerifier = conceroVerifier;
        i_conceroVerifierSubId = conceroVerifierSubId;
    }

    function _isAuthorizedClfSigner(address clfSigner) internal view returns (bool) {
        if (clfSigner == address(0)) {
            return false;
        }

        return (clfSigner == i_clfSigner0 ||
            clfSigner == i_clfSigner1 ||
            clfSigner == i_clfSigner2 ||
            clfSigner == i_clfSigner3);
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

    function _verifyClfReportOnChainMetadata(
        Types.ClfReportOnchainMetadata memory onchainMetadata
    ) internal view {
        require(onchainMetadata.client == i_conceroVerifier, InvalidClfReportClient());
        require(
            onchainMetadata.subscriptionId == i_conceroVerifierSubId,
            InvalidClfReportSubscriptionId()
        );
    }
    /**
     * @notice Verifies the signatures of the report.
     * @param reportSubmission The report submission data.
     */
    function _verifyClfReportSignatures(
        Types.ClfDonReportSubmission calldata reportSubmission
    ) internal view {
        bytes32 clfReportHash = _computeCLFReportHash(
            reportSubmission.context,
            reportSubmission.report
        );
        bytes32[] memory rs = reportSubmission.rs;
        bytes32[] memory ss = reportSubmission.ss;
        bytes memory rawVs = reportSubmission.rawVs;

        uint256 expectedNumSignatures = 3;

        require(
            rs.length == ss.length && rs.length == expectedNumSignatures,
            IncorrectNumberOfSignatures()
        );

        address[] memory signers = new address[](rs.length);

        for (uint256 i; i < rs.length; ++i) {
            address signer = ecrecover(clfReportHash, uint8(rawVs[i]) + 27, rs[i], ss[i]);
            require(_isAuthorizedClfSigner(signer), UnauthorizedSigner(signer));

            for (uint256 j = 0; j < i; j++) {
                require(signers[j] != signer, DuplicateSignatureDetected(signer));
            }

            signers[i] = signer;
        }
    }
}
