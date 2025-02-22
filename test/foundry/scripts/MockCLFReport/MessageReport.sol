pragma solidity 0.8.28;

import {BaseMockCLFReport} from "./BaseMockCLFReport.sol";
import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {ReportConfigBitOffsets} from "contracts/common/CommonConstants.sol";
import {Types as RouterTypes} from "contracts/ConceroRouter/libraries/Types.sol";

contract MessageReport is BaseMockCLFReport {
    function getReport() public pure returns (RouterTypes.ClfDonReportSubmission memory) {
        return createMockClfReport(getResponse());
    }

    function getResponse() internal pure returns (bytes memory) {
        CommonTypes.MessageReportResult memory result;
        address requester = address(operator);

        result.reportConfig =
            (uint256(uint8(CommonTypes.CLFReportType.Message)) <<
                ReportConfigBitOffsets.OFFSET_REPORT_TYPE) |
            (uint256(1) << ReportConfigBitOffsets.OFFSET_VERSION) |
            (uint256(uint160(requester)));

        result.internalMessageConfig = INTERNAL_MESSAGE_CONFIG;
        result.messageId = bytes32("messageId");
        result.messageHashSum = bytes32("messageHashSum");
        result.dstChainData = "dstChain";
        result.allowedOperators = new bytes[](1);
        result.allowedOperators[0] = abi.encodePacked(
            address(0x3333333333333333333333333333333333333333)
        );

        return abi.encode(result);
    }
}
