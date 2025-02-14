pragma solidity 0.8.28;

import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {ReportConfigBitOffsets} from "contracts/common/CommonConstants.sol";

import {Types} from "contracts/ConceroVerifier/libraries/Types.sol";
import {Types as RouterTypes} from "contracts/ConceroRouter/libraries/Types.sol";
import {ConceroVerifierTest} from "../ConceroVerifier/base/ConceroVerifierTest.sol";

contract MockCLFReport is ConceroVerifierTest {
    error IncorrectNumberOfSignatures();
    error UnauthorizedSigner(address signer);
    error DuplicateSignatureDetected(address signer);

    function run() external {
        RouterTypes.ClfDonReportSubmission memory reportSubmission = createMessageReport();
        _verifyClfReportSignatures(reportSubmission);
    }

    /**
     * @notice Creates a mock CLF report signed by 4 mock DON signers.
     * @return reportSubmission The constructed CLF report submission.
     */
    function createMockClfReport(
        bytes memory _response
    ) public pure returns (RouterTypes.ClfDonReportSubmission memory reportSubmission) {
        bytes32[3] memory context = [bytes32("context0"), bytes32("context1"), bytes32("context2")];

        bytes32[] memory requestIds = new bytes32[](1);
        bytes[] memory results = new bytes[](1);
        results[0] = _response;
        bytes[] memory errors = new bytes[](1);
        bytes[] memory onchainMetadata = new bytes[](1);
        bytes[] memory offchainMetadata = new bytes[](1);
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
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(mockDonPrivateKeys[i], h);
            rs[i] = r;
            ss[i] = s;
            rawVs[i] = bytes1(v - 27);
        }

        reportSubmission = RouterTypes.ClfDonReportSubmission({
            context: context,
            report: reportBody,
            rs: rs,
            ss: ss,
            rawVs: rawVs
        });
    }

    /**
     * @notice Returns a mock message report response using the MessageReportResult struct.
     * @return response The encoded message report response.
     */
    function getMockMessageReportResponse() internal pure returns (bytes memory response) {
        CommonTypes.MessageReportResult memory result;

        address requester = address(0x1234567890123456789012345678901234567890);

        result.reportConfig =
            (uint256(uint8(CommonTypes.CLFReportType.Message)) <<
                (ReportConfigBitOffsets.OFFSET_REPORT_TYPE)) |
            (uint256(1) << (ReportConfigBitOffsets.OFFSET_VERSION)) |
            (uint256(uint160(requester))); // last 20 bytes

        result.internalMessageConfig = INTERNAL_MESSAGE_CONFIG;
        result.messageId = bytes32("messageId");
        result.messageHashSum = bytes32("messageHashSum");
        result.dstChainData = "dstChain";
        result.allowedOperators = new bytes[](1);
        result.allowedOperators[0] = abi.encodePacked(
            address(0x3333333333333333333333333333333333333333)
        );

        response = abi.encode(result);
    }

    /**
     * @notice Returns a mock operator registration response using the OperatorRegistrationResult struct.
     * @param operator The address of the operator
     * @return response The encoded operator registration report response.
     */
    function getMockOperatorRegistrationResponse(
        address operator
    ) internal pure returns (bytes memory response) {
        Types.OperatorRegistrationResult memory result;

        address requester = address(0x1234567890123456789012345678901234567890);

        result.reportConfig =
            (uint256(uint8(CommonTypes.CLFReportType.OperatorRegistration)) <<
                (ReportConfigBitOffsets.OFFSET_REPORT_TYPE)) |
            (uint256(1) << (ReportConfigBitOffsets.OFFSET_VERSION)) |
            (uint256(uint160(requester))); // last 20 bytes

        result.operatorChains = new CommonTypes.ChainType[](1);
        result.operatorChains[0] = CommonTypes.ChainType.EVM;
        result.operatorActions = new Types.OperatorRegistrationAction[](1);
        result.operatorActions[0] = Types.OperatorRegistrationAction.Register;
        result.operatorAddresses = new bytes[](1);
        result.operatorAddresses[0] = abi.encodePacked(
            bytes20(0x4444444444444444444444444444444444444444)
        );

        response = abi.encode(result);
    }

    /**
     * @notice Creates a mock CLF report for a message report.
     * @return reportSubmission The constructed CLF report submission with a message report response.
     */
    function createMessageReport()
        public
        returns (RouterTypes.ClfDonReportSubmission memory reportSubmission)
    {
        bytes memory response = getMockMessageReportResponse();
        reportSubmission = createMockClfReport(response);
    }

    /**
     * @notice Creates a mock CLF report for an operator registration report.
     * @return reportSubmission The constructed CLF report submission with an operator registration response.
     */
    function createOperatorRegistrationReport()
        public
        returns (RouterTypes.ClfDonReportSubmission memory reportSubmission)
    {
        bytes memory response = getMockOperatorRegistrationResponse(operator);
        reportSubmission = createMockClfReport(response);
    }

    function _isAuthorizedClfSigner(address signer) internal pure returns (bool) {
        return
            signer == MOCK_DON_SIGNER_ADDRESS_0 ||
            signer == MOCK_DON_SIGNER_ADDRESS_1 ||
            signer == MOCK_DON_SIGNER_ADDRESS_2 ||
            signer == MOCK_DON_SIGNER_ADDRESS_3;
    }

    function _computeCLFReportHash(
        bytes32[3] memory reportContext,
        bytes memory report
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
        RouterTypes.ClfDonReportSubmission memory reportSubmission
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
            require(_isAuthorizedClfSigner(signer), UnauthorizedSigner(signer));

            for (uint256 j = 0; j < i; j++) {
                require(signers[j] != signer, DuplicateSignatureDetected(signer));
            }

            signers[i] = signer;
        }
    }
}
