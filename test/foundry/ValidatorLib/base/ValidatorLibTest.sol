// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ValidatorLib} from "contracts/ValidatorLib/ValidatorLib.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {ConceroTest} from "../../utils/ConceroTest.sol";
import {ConceroClientExample} from "contracts/examples/ConceroClientExample.sol";
import {ConceroRouterHarness} from "../../harnesses/ConceroRouterHarness.sol";
import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {Types} from "contracts/ValidatorLib/libraries/Types.sol";
import {ConceroRouter} from "contracts/ConceroRouter/ConceroRouter.sol";
import {MessageReport as MockCLFReport} from "../../scripts/MockCLFReport/MessageReport.sol";
import {DeployValidatorLib} from "../../scripts/deploy/DeployValidatorLib.s.sol";

abstract contract ValidatorLibTest is ConceroTest {
    address public constant MOCK_DON_SIGNER_ADDRESS_0 = 0x0004C7EdCF9283D3bc3C1309939b3E887bb9d98b;
    address public constant MOCK_DON_SIGNER_ADDRESS_1 = 0x000437D9bE1C11B748e8B4C349b818eE82682E9f;
    address public constant MOCK_DON_SIGNER_ADDRESS_2 = 0x000E512Da9116546247eE54Ffef6319E00331E1B;
    address public constant MOCK_DON_SIGNER_ADDRESS_3 = 0x0001E5818621C01908e989851ECB899Af3d57bDc;
    uint8 internal constant VALIDATOR_LIB_FEE_BPS_USD = 100;

    ValidatorLib internal validatorLib;
    ConceroClientExample internal conceroClient;
    ConceroRouterHarness internal conceroRouter;
    MockCLFReport internal mockClfReport;
    DeployValidatorLib deployValidatorLib;

    function setUp() public virtual {
        deployValidatorLib = new DeployValidatorLib();

        validatorLib = new ValidatorLib(
            DST_CHAIN_SELECTOR,
            address(s_conceroPriceFeed),
            address(s_conceroValidator),
            deployValidatorLib.s_conceroValidatorSubscriptionId(),
            [
                MOCK_DON_SIGNER_ADDRESS_0,
                MOCK_DON_SIGNER_ADDRESS_1,
                MOCK_DON_SIGNER_ADDRESS_2,
                MOCK_DON_SIGNER_ADDRESS_3
            ]
        );
        mockClfReport = new MockCLFReport(
            address(s_conceroValidator),
            deployValidatorLib.s_conceroValidatorSubscriptionId(),
            s_operator,
            SRC_CHAIN_SELECTOR,
            DST_CHAIN_SELECTOR,
            s_user
        );
        conceroRouter = ConceroRouterHarness(
            payable(new ConceroRouter(DST_CHAIN_SELECTOR, address(s_conceroPriceFeed)))
        );
        conceroClient = new ConceroClientExample(payable(conceroRouter));
    }

    function _createDstChainData(
        address receiver,
        uint256 gasLimit
    ) internal pure returns (Types.EvmDstChainData memory) {
        return Types.EvmDstChainData({receiver: receiver, gasLimit: gasLimit});
    }

    function _createResultConfig(
        address requester
    ) internal pure returns (CommonTypes.ResultConfig memory) {
        return
            CommonTypes.ResultConfig({
                resultType: CommonTypes.ResultType.Message,
                payloadVersion: 1,
                requester: requester
            });
    }

    function _createAllowedOperators(
        address operatorAddress
    ) internal pure returns (bytes[] memory) {
        bytes[] memory allowedOperators = new bytes[](1);
        allowedOperators[0] = abi.encode(operatorAddress);
        return allowedOperators;
    }

    function _createMessagePayload(
        bytes32 messageId,
        bytes32 messageHashSum,
        uint24 srcChainSelector,
        uint24 dstChainSelector,
        Types.EvmDstChainData memory dstChainData,
        bytes[] memory allowedOperators
    ) internal view returns (CommonTypes.MessagePayloadV1 memory) {
        return
            CommonTypes.MessagePayloadV1({
                messageId: messageId,
                messageHashSum: messageHashSum,
                txHash: bytes32("txHash"),
                messageSender: abi.encode(address(this)),
                srcChainSelector: srcChainSelector,
                dstChainSelector: dstChainSelector,
                srcBlockNumber: block.number,
                dstChainData: dstChainData,
                allowedOperators: allowedOperators
            });
    }

    function _createMessageRequest(
        uint24 dstChainSelector,
        Types.EvmDstChainData memory dstChainData,
        bytes memory payload
    ) internal pure returns (IConceroRouter.MessageRequest memory) {
        return
            IConceroRouter.MessageRequest({
                dstChainSelector: dstChainSelector,
                srcBlockConfirmations: uint64(1),
                feeToken: address(0),
                relayerLib: address(0),
                validatorLibs: new address[](0),
                validatorConfigs: new bytes[](0),
                relayerConfig: new bytes(0),
                validationRpcs: new bytes[](0),
                deliveryRpcs: new bytes[](0),
                dstChainData: abi.encode(dstChainData),
                payload: payload
            });
    }
}
