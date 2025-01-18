//SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library Signer {
    error IncorrectNumberOfSignatures();
    error UnauthorizedSigner(address signer);
    error DuplicateSignatureDetected(address signer);

    struct ClfDonReportSubmission {
        bytes32[3] context;
        bytes report;
        bytes32[] rs;
        bytes32[] ss;
        bytes rawVs;
    }

    /* CLF DON SIGNERS */
    address internal constant CLF_DON_SIGNER_0 = 0xCCCcAC597660Eebf71b424415f874ee4c6b13D22;
    address internal constant CLF_DON_SIGNER_1 = 0xCCCcAC597660Eebf71b424415f874ee4c6b13D22;
    address internal constant CLF_DON_SIGNER_2 = 0xCCCcAC597660Eebf71b424415f874ee4c6b13D22;
    address internal constant CLF_DON_SIGNER_3 = 0xCCCcAC597660Eebf71b424415f874ee4c6b13D22;

    function _isAuthorizedClfDonSigner(address clfDonSigner) internal view returns (bool) {
        if (clfDonSigner == address(0)) {
            return false;
        }

        return (clfDonSigner == CLF_DON_SIGNER_0 ||
            clfDonSigner == CLF_DON_SIGNER_1 ||
            clfDonSigner == CLF_DON_SIGNER_2 ||
            clfDonSigner == CLF_DON_SIGNER_3);
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

        for (uint256 i; i < rs.length; i++) {
            uint8 v = uint8(rawVs[i]) + 27;
            bytes32 r = rs[i];
            bytes32 s = ss[i];

            address signer = ecrecover(clfReportHash, v, r, s);
            require(_isAuthorizedClfDonSigner(signer), UnauthorizedSigner(signer));

            for (uint256 j = 0; j < i; j++) {
                require(signers[j] != signer, DuplicateSignatureDetected(signer));
            }

            signers[i] = signer;
        }
    }
}
