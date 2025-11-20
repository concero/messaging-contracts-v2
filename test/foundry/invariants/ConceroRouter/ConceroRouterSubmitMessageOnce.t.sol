// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroRouterTest} from "../../ConceroRouter/base/ConceroRouterTest.sol";
import {MessageCodec} from "../../../../contracts/common/libraries/MessageCodec.sol";
import {IConceroRouter} from "../../../../contracts/interfaces/IConceroRouter.sol";
import {IRelayer} from "../../../../contracts/interfaces/IRelayer.sol";
import {ConceroTestClient} from "../../ConceroTestClient/ConceroTestClient.sol";
import {console} from "forge-std/src/console.sol";

contract ConceroRouterSubmitMessageHandler {
    using MessageCodec for IConceroRouter.MessageRequest;

    uint32 public constant GAS_LIMIT = 1_000_000;

    IConceroRouter internal immutable i_conceroRouter;
    ConceroTestClient public i_conceroClient;
    address public immutable i_relayerLib;
    address public immutable i_validatorLib;
    uint24 public immutable i_dstChainSelector;

    bytes[] public s_receipts;
    mapping(bytes32 => uint256) public s_processedCount;

    bool public isReverted;

    constructor(
        address router,
        ConceroTestClient client,
        address relayerLib,
        address validatorLib,
        uint24 dstChainSelector
    ) {
        i_conceroRouter = IConceroRouter(router);
        i_conceroClient = client;
        i_relayerLib = relayerLib;
        i_validatorLib = validatorLib;
        i_dstChainSelector = dstChainSelector;
    }

    function submitNew(
        uint64 srcBlockConfirmations,
        uint24 srcChainSelector,
        bytes memory payload,
        uint256 nonce
    ) external {
        IConceroRouter.MessageRequest memory req = _buildMessageRequest(
            srcBlockConfirmations,
            GAS_LIMIT,
            payload
        );

        bytes memory receipt = req.toMessageReceiptBytes(srcChainSelector, address(this), nonce);

        _submit(receipt);
    }

    function resubmitExisting(uint256 index) external {
        if (s_receipts.length == 0) return;
        index = index % s_receipts.length;
        bytes memory receipt = s_receipts[index];

        _submit(receipt);
    }

    function _submit(bytes memory receipt) internal {
        bytes[] memory validations = new bytes[](1);
        validations[0] = abi.encode(uint256(1));
        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = address(i_validatorLib);

        (bool ok, bytes memory res) = address(i_conceroRouter).call(
            abi.encodeWithSelector(
                IRelayer.submitMessage.selector,
                receipt,
                validations,
                validatorLibs,
                i_relayerLib
            )
        );

        if (!ok) {
            if (bytes4(res) != IRelayer.MessageAlreadyProcessed.selector) {
                isReverted = true;
            }

            return;
        }

        bytes32 messageId = keccak256(receipt);

        if (s_processedCount[messageId] == 0) {
            s_receipts.push(receipt);
        }

        s_processedCount[messageId] += 1;
    }

    function receiptsLength() external view returns (uint256) {
        return s_receipts.length;
    }

    function receiptAt(uint256 i) external view returns (bytes memory) {
        return s_receipts[i];
    }

    function processedCountOf(bytes32 hash) external view returns (uint256) {
        return s_processedCount[hash];
    }

    function _buildMessageRequest(
        uint64 srcBlockConfirmations,
        uint32 dstChainGasLimit,
        bytes memory payload
    ) internal view returns (IConceroRouter.MessageRequest memory) {
        address[] memory validatorLibs = new address[](1);
        validatorLibs[0] = i_validatorLib;

        return
            IConceroRouter.MessageRequest({
                dstChainSelector: i_dstChainSelector,
                srcBlockConfirmations: srcBlockConfirmations,
                feeToken: address(0),
                dstChainData: MessageCodec.encodeEvmDstChainData(
                    address(i_conceroClient),
                    dstChainGasLimit
                ),
                validatorLibs: validatorLibs,
                relayerLib: i_relayerLib,
                validatorConfigs: new bytes[](1),
                relayerConfig: new bytes(0),
                payload: payload
            });
    }
}

contract ConceroRouterSubmitMessageOnce is ConceroRouterTest {
    ConceroRouterSubmitMessageHandler internal s_conceroRouterHandler;

    function setUp() public override {
        super.setUp();

        s_conceroRouterHandler = new ConceroRouterSubmitMessageHandler(
            address(s_dstConceroRouter),
            s_conceroClient,
            s_relayerLib,
            s_validatorLib,
            DST_CHAIN_SELECTOR
        );

        targetContract(address(s_conceroRouterHandler));
    }

    function invariant_messageProcessedAtMostOnce() public view {
        assert(!s_conceroRouterHandler.isReverted());

        uint256 len = s_conceroRouterHandler.receiptsLength();

        for (uint256 i; i < len; ++i) {
            bytes memory receipt = s_conceroRouterHandler.receiptAt(i);
            bytes32 messageId = keccak256(receipt);

            assertLe(
                s_conceroRouterHandler.processedCountOf(messageId),
                1,
                "message processed more than once"
            );
        }
    }
}
