pragma solidity 0.8.28;

import {console} from "forge-std/src/console.sol";
import {BaseMockCLFReport} from "./BaseMockCLFReport.sol";
import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {ReportConfigBitOffsets} from "contracts/common/CommonConstants.sol";
import {Types as VerifierTypes} from "contracts/ConceroVerifier/libraries/Types.sol";
import {Types as RouterTypes} from "contracts/ConceroRouter/libraries/Types.sol";

contract OperatorRegistrationReport is BaseMockCLFReport {
    function getReport() public pure returns (RouterTypes.ClfDonReportSubmission memory) {
        return getReport(getResponse());
    }

    function getReport(
        bytes memory expectedResponse
    ) public pure returns (RouterTypes.ClfDonReportSubmission memory) {
        return createMockClfReport(expectedResponse);
    }

    function getResponse() public pure returns (bytes memory) {
        return getResponse(address(operator));
    }

    function getResponse(address operator) public pure returns (bytes memory) {
        VerifierTypes.OperatorRegistrationResult memory result;

        result.reportConfig = bytes32(
            (uint256(uint8(CommonTypes.CLFReportType.OperatorRegistration)) <<
                ReportConfigBitOffsets.OFFSET_REPORT_TYPE) |
                (uint256(1) << ReportConfigBitOffsets.OFFSET_VERSION) |
                uint256(uint160(operator))
        );

        result.operatorChains = new CommonTypes.ChainType[](1);
        result.operatorChains[0] = CommonTypes.ChainType.EVM;

        result.operatorActions = new VerifierTypes.OperatorRegistrationAction[](1);
        result.operatorActions[0] = VerifierTypes.OperatorRegistrationAction.Register;

        result.operatorAddresses = new bytes[](1);
        result.operatorAddresses[0] = abi.encode(operator); // Changed from encodePacked to encode

        // We need to create a proper ABI encoding of the entire struct
        return
            abi.encode(
                result.reportConfig,
                result.operatorChains,
                result.operatorActions,
                result.operatorAddresses
            );
    }
}
