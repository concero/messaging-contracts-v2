// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {MessageCodec} from "contracts/common/libraries/MessageCodec.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {IRelayerLib} from "contracts/interfaces/IRelayerLib.sol";
import {IValidatorLib} from "contracts/interfaces/IValidatorLib.sol";
import {ConceroTest} from "../../utils/ConceroTest.sol";
import {ConceroTestClient} from "../../ConceroTestClient/ConceroTestClient.sol";
import {MockConceroValidatorLib} from "../../mocks/MockConceroValidatorLib.sol";
import {MockConceroRouter} from "../../mocks/MockConceroRouter.sol"; // TODO: Remove this
import {MockConceroRelayerLib} from "../../mocks/MockConceroRelayerLib.sol";

contract ConceroClientTest is ConceroTest {
    ConceroTestClient internal s_conceroClient;
    MockConceroRouter internal s_mockConceroRouter;

    address internal s_validatorLib = address(new MockConceroValidatorLib());
    address internal s_relayerLib = address(new MockConceroRelayerLib());

    function setUp() public virtual {
        s_mockConceroRouter = new MockConceroRouter();
        s_conceroClient = new ConceroTestClient(payable(address(s_mockConceroRouter)));

        s_conceroClient.setIsRelayerAllowed(s_relayerLib, true);
        s_conceroClient.setIsValidatorAllowed(s_validatorLib, true);
        s_conceroClient.setRequiredValidatorsCount(1);
    }

    function _buildMessageRequest() internal view returns (IConceroRouter.MessageRequest memory) {
        return _buildMessageRequest("Test message", 300_000, 10, address(0));
    }

    function _buildMessageRequest(
        bytes memory payload,
        uint32 dstChainGasLimit,
        uint64 srcBlockConfirmations,
        address feeToken
    ) internal view returns (IConceroRouter.MessageRequest memory) {
        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = s_validatorLib;

        return
            IConceroRouter.MessageRequest({
                dstChainSelector: DST_CHAIN_SELECTOR,
                srcBlockConfirmations: srcBlockConfirmations,
                feeToken: feeToken,
                dstChainData: MessageCodec.encodeEvmDstChainData(
                    address(s_conceroClient),
                    dstChainGasLimit
                ),
                validatorLibs: validatorLibs,
                relayerLib: s_relayerLib,
                validatorConfigs: new bytes[](1),
                relayerConfig: new bytes(1),
                validationRpcs: new bytes[](0),
                deliveryRpcs: new bytes[](0),
                payload: payload
            });
    }

    function _buildMessageReceipt() internal view returns (bytes memory) {
        bytes[] memory dstValidatorLibs = new bytes[](1);
        dstValidatorLibs[0] = IValidatorLib(s_validatorLib).getDstLib(DST_CHAIN_SELECTOR);

        return
            _buildMessageReceipt(
                _buildMessageRequest(),
                IRelayerLib(s_relayerLib).getDstLib(DST_CHAIN_SELECTOR),
                dstValidatorLibs
            );
    }

    function _buildMessageReceipt(
        IConceroRouter.MessageRequest memory messageRequest,
        bytes memory dstRelayerLib,
        bytes[] memory dstValidatorLibs
    ) internal view returns (bytes memory) {
        return
            MessageCodec.toMessageReceiptBytes(
                messageRequest,
                SRC_CHAIN_SELECTOR,
                s_user,
                1,
                dstRelayerLib,
                dstValidatorLibs
            );
    }
}
