pragma solidity 0.8.28;

import {BaseMockCLFReport} from "./BaseMockCLFReport.sol";
import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {ReportConfigBitOffsets} from "contracts/common/CommonConstants.sol";
import {Types as VerifierTypes} from "contracts/ConceroVerifier/libraries/Types.sol";
import {Types as RouterTypes} from "contracts/ConceroRouter/libraries/Types.sol";

contract OperatorRegistrationReport is BaseMockCLFReport {
    function getReport() public view returns (RouterTypes.ClfDonReportSubmission memory) {
        return getReport(getResponse(), bytes32("requestId"));
    }

    function getReport(
        bytes memory expectedResponse,
        bytes32 clfRequestId
    ) public view returns (RouterTypes.ClfDonReportSubmission memory) {
        return createMockClfReport(expectedResponse, clfRequestId);
    }

    function getResponse() public pure returns (bytes memory) {
        return getResponse(address(operator));
    }

    function getResponse(address requester) public pure returns (bytes memory) {
        VerifierTypes.OperatorRegistrationResult memory result;
        CommonTypes.ResultType resultType = CommonTypes.ResultType.OperatorRegistration;
        uint8 payloadVersion = 1;

        result.operatorChains = new CommonTypes.ChainType[](1);
        result.operatorChains[0] = CommonTypes.ChainType.EVM;

        result.operatorActions = new VerifierTypes.OperatorRegistrationAction[](1);
        result.operatorActions[0] = VerifierTypes.OperatorRegistrationAction.Register;

        result.operatorAddresses = new bytes[](1);
        result.operatorAddresses[0] = abi.encode(requester);

        VerifierTypes.OperatorRegistrationResult memory payload = VerifierTypes
            .OperatorRegistrationResult({
                operatorChains: result.operatorChains,
                operatorActions: result.operatorActions,
                operatorAddresses: result.operatorAddresses
            });

        CommonTypes.ResultConfig memory resultConfig = CommonTypes.ResultConfig({
            resultType: resultType,
            payloadVersion: payloadVersion,
            requester: requester
        });

        return abi.encode(resultConfig, abi.encode(payload));
    }
}
