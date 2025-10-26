//// SPDX-License-Identifier: UNLICENSED
///**
// * @title Security Reporting
// * @notice If you discover any security vulnerabilities, please report them responsibly.
// * @contact email: security@concero.io
// */
//pragma solidity 0.8.28;
//
//import {ValidatorLib} from "contracts/ValidatorLib/ValidatorLib.sol";
//import {ConceroTest} from "../../utils/ConceroTest.sol";
//import {DeployValidatorLib} from "../../scripts/deploy/DeployValidatorLib.s.sol";
//import {ConceroClientExample} from "../../../../contracts/examples/ConceroClientExample.sol";
//import {ConceroRouterHarness} from "../../harnesses/ConceroRouterHarness.sol";
//import {CommonTypes} from "contracts/common/CommonTypes.sol";
//import {ConceroTypes} from "contracts/ConceroClient/ConceroTypes.sol";
//import {Types} from "../../../../contracts/ValidatorLib/libraries/Types.sol";
//
//abstract contract ValidatorLibTest is DeployValidatorLib, ConceroTest {
//    ConceroClientExample internal conceroClient;
//    ConceroRouterHarness internal conceroRouter;
//
//    function setUp() public virtual override(DeployValidatorLib, ConceroTest) {
//        super.setUp();
//
//        validatorLib = ValidatorLib(deploy(DST_CHAIN_SELECTOR, address(conceroPriceFeed)));
//        conceroRouter = ConceroRouterHarness(
//            payable(deploy(DST_CHAIN_SELECTOR, address(conceroPriceFeed)))
//        );
//        conceroClient = new ConceroClientExample(payable(conceroRouter));
//    }
//
//    function _createDstChainData(
//        address receiver,
//        uint256 gasLimit
//    ) internal pure returns (Types.EvmDstChainData memory) {
//        return Types.EvmDstChainData({receiver: receiver, gasLimit: gasLimit});
//    }
//
//    function _createResultConfig(
//        address requester
//    ) internal pure returns (CommonTypes.ResultConfig memory) {
//        return
//            CommonTypes.ResultConfig({
//                resultType: CommonTypes.ResultType.Message,
//                payloadVersion: 1,
//                requester: requester
//            });
//    }
//
//    function _createAllowedOperators(
//        address operatorAddress
//    ) internal pure returns (bytes[] memory) {
//        bytes[] memory allowedOperators = new bytes[](1);
//        allowedOperators[0] = abi.encode(operatorAddress);
//        return allowedOperators;
//    }
//
//    function _createMessagePayload(
//        bytes32 messageId,
//        bytes32 messageHashSum,
//        uint24 srcChainSelector,
//        uint24 dstChainSelector,
//        Types.EvmDstChainData memory dstChainData,
//        bytes[] memory allowedOperators
//    ) internal view returns (CommonTypes.MessagePayloadV1 memory) {
//        return
//            CommonTypes.MessagePayloadV1({
//                messageId: messageId,
//                messageHashSum: messageHashSum,
//                txHash: bytes32("txHash"),
//                messageSender: abi.encode(address(this)),
//                srcChainSelector: srcChainSelector,
//                dstChainSelector: dstChainSelector,
//                srcBlockNumber: block.number,
//                dstChainData: dstChainData,
//                allowedOperators: allowedOperators
//            });
//    }
//
//    function _createMessageRequest(
//        uint24 srcChainSelector,
//        uint24 dstChainSelector,
//        address receiver,
//        uint256 gasLimit,
//        bytes memory payload
//    ) internal view returns (ConceroTypes.MessageRequest memory) {
//        return
//            ConceroTypes.MessageRequest({
//                sender: abi.encode(address(this)),
//                srcChainSelector: srcChainSelector,
//                dstChainSelector: dstChainSelector,
//                dstChainData: ConceroTypes.EvmDstChainData({
//                    receiver: receiver,
//                    gasLimit: gasLimit
//                }),
//                validatorsConfig: new bytes[](0),
//                relayerConfig: bytes(""),
//                payload: payload
//            });
//    }
//
//    function _createMessageHeader() internal pure returns (ConceroTypes.MessageHeader memory) {
//        return
//            ConceroTypes.MessageHeader({
//                srcBlockConfirmations: 10,
//                validatorsLibs: new address[](0),
//                relayerLib: address(0),
//                validationRPCs: new bytes[](0),
//                deliveryRPCs: new bytes[](0),
//                feeToken: address(0)
//            });
//    }
//}
