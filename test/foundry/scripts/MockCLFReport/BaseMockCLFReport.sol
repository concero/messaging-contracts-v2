// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroVerifierTest} from "../../ConceroVerifier/base/ConceroVerifierTest.sol";
import {Types as RouterTypes} from "contracts/ConceroRouter/libraries/Types.sol";

contract BaseMockCLFReport is ConceroVerifierTest {
    function createMockClfReport(
        bytes memory _response
    ) public view returns (RouterTypes.ClfDonReportSubmission memory) {
        return
            createMockClfReport(
                _response,
                bytes32("requestId"),
                CONCERO_VERIFIER_ADDRESS,
                i_conceroVerifierSubscriptionId
            );
    }

    function createMockClfReport(
        bytes memory _response,
        bytes32 requestId
    ) public view returns (RouterTypes.ClfDonReportSubmission memory) {
        return
            createMockClfReport(
                _response,
                requestId,
                CONCERO_VERIFIER_ADDRESS,
                i_conceroVerifierSubscriptionId
            );
    }

    function createMockClfReport(
        bytes memory _response,
        bytes32 requestId,
        address client,
        uint64 subscriptionId
    ) public pure returns (RouterTypes.ClfDonReportSubmission memory) {
        bytes32[3] memory context = [bytes32("context0"), bytes32("context1"), bytes32("context2")];

        bytes32[] memory requestIds = new bytes32[](1);
        requestIds[0] = requestId;

        bytes[] memory results = new bytes[](1);
        results[0] = _response;

        bytes[] memory errors = new bytes[](1);
        bytes[] memory onchainMetadata = new bytes[](1);

        onchainMetadata[0] = abi.encode(
            RouterTypes.ClfReportOnchainMetadata({
                requestId: requestId, // Use the provided request ID
                coordinator: address(0x1234567890123456789012345678901234567890),
                estimatedTotalCostJuels: 1000000000000000000,
                client: client,
                subscriptionId: subscriptionId,
                callbackGasLimit: 100000,
                adminFee: 1000000000000000000,
                donFee: 1000000000000000000,
                gasOverheadBeforeCallback: 100000,
                gasOverheadAfterCallback: 100000,
                timeoutTimestamp: 100000
            })
        );

        return
            _createReportSubmission(
                context,
                requestIds,
                results,
                errors,
                onchainMetadata,
                new bytes[](1)
            );
    }

    function _createReportSubmission(
        bytes32[3] memory context,
        bytes32[] memory requestIds,
        bytes[] memory results,
        bytes[] memory errors,
        bytes[] memory onchainMetadata,
        bytes[] memory offchainMetadata
    ) internal pure returns (RouterTypes.ClfDonReportSubmission memory) {
        bytes memory reportBody = abi.encode(
            requestIds,
            results,
            errors,
            onchainMetadata,
            offchainMetadata
        );

        bytes32 reportHash = keccak256(reportBody);
        bytes memory message = abi.encodePacked(reportHash, context[0], context[1], context[2]);
        bytes32 h = keccak256(message);

        (bytes32[] memory rs, bytes32[] memory ss, bytes32 rawVs) = _generateSignatures(h);

        return
            RouterTypes.ClfDonReportSubmission({
                context: context,
                report: reportBody,
                rs: rs,
                ss: ss,
                rawVs: rawVs
            });
    }

    function _generateSignatures(
        bytes32 hash
    ) internal pure returns (bytes32[] memory, bytes32[] memory, bytes32) {
        uint256 numSignatures = 3;
        bytes32[] memory rs = new bytes32[](numSignatures);
        bytes32[] memory ss = new bytes32[](numSignatures);
        bytes memory rawVs = new bytes(numSignatures);

        uint256[3] memory mockDonPrivateKeys = [
            MOCK_DON_SIGNER_PRIVATE_KEY_0,
            MOCK_DON_SIGNER_PRIVATE_KEY_1,
            MOCK_DON_SIGNER_PRIVATE_KEY_2
        ];

        for (uint256 i = 0; i < numSignatures; i++) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(mockDonPrivateKeys[i], hash);

            rs[i] = r;
            ss[i] = s;

            rawVs[i] = bytes1(v - 27);
        }

        return (rs, ss, bytes32(rawVs));
    }
}
