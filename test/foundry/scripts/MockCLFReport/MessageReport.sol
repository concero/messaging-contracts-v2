pragma solidity 0.8.28;

import {BaseMockCLFReport} from "./BaseMockCLFReport.sol";
import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {ReportConfigBitOffsets} from "contracts/common/CommonConstants.sol";
import {Types as RouterTypes} from "contracts/ConceroRouter/libraries/Types.sol";

contract MessageReport is BaseMockCLFReport {
    function getReport() public pure returns (RouterTypes.ClfDonReportSubmission memory) {
        return getReport(getResponse());
    }

    function getReport(
        bytes memory expectedResponse
    ) public pure returns (RouterTypes.ClfDonReportSubmission memory) {
        return createMockClfReport(expectedResponse);
    }

    function getResponse() public pure returns (bytes memory) {
        return
            getResponse(
                address(operator),
                INTERNAL_MESSAGE_CONFIG,
                bytes32("messageId"),
                bytes32("messageHashSum"),
                "dstChain",
                new bytes[](0)
            );
    }

    function getResponse(
        address requester,
        bytes32 internalMessageConfig,
        bytes32 messageId,
        bytes32 messageHashSum,
        bytes memory dstChainData,
        bytes[] memory allowedOperators
    ) public pure returns (bytes memory) {
        bytes32 reportConfig = bytes32(
            (uint256(uint8(CommonTypes.CLFReportType.Message)) <<
                ReportConfigBitOffsets.OFFSET_REPORT_TYPE) |
                (uint256(1) << ReportConfigBitOffsets.OFFSET_VERSION) |
                (uint256(uint160(requester)))
        );

        return
            abi.encode(
                reportConfig,
                internalMessageConfig,
                messageId,
                messageHashSum,
                dstChainData,
                allowedOperators
            );
    }
}
