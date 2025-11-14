// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {RelayerLib} from "contracts/RelayerLib/RelayerLib.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {ConceroTest} from "../../utils/ConceroTest.sol";
import {MessageCodec} from "contracts/common/libraries/MessageCodec.sol";
import {ConceroRouter} from "contracts/ConceroRouter/ConceroRouter.sol";
import {Storage as s} from "contracts/ConceroRouter/libraries/Storage.sol";

contract MockConceroRouterWithFee is ConceroRouter {
    using s for s.Router;

    constructor(
        uint24 chainSelector,
        address conceroPriceFeed
    ) ConceroRouter(chainSelector, conceroPriceFeed) {}

    function setRelayerFee(address relayerLib, uint256 relayerFee, address feeToken) external {
        s.router().relayerFeeEarned[relayerLib][feeToken] = relayerFee;
        s.router().totalRelayerFeeEarned[feeToken] = relayerFee;
    }
}

abstract contract RelayerLibTest is ConceroTest {
    RelayerLib internal s_relayerLib;
    MockConceroRouterWithFee internal mockConceroRouterWithFee;

    function setUp() public virtual {
        mockConceroRouterWithFee = new MockConceroRouterWithFee(
            SRC_CHAIN_SELECTOR,
            address(s_conceroPriceFeed)
        );

        s_relayerLib = new RelayerLib(
            SRC_CHAIN_SELECTOR,
            address(s_conceroPriceFeed),
            address(mockConceroRouterWithFee)
        );
        s_relayerLib.setSubmitMsgGasOverhead(SUBMIT_MSG_GAS_OVERHEAD);
    }

    function _createMessageRequest(
        uint24 dstChainSelector,
        uint32 gasLimit
    ) internal view returns (IConceroRouter.MessageRequest memory) {
        return
            IConceroRouter.MessageRequest({
                dstChainSelector: dstChainSelector,
                srcBlockConfirmations: uint64(1),
                feeToken: address(0),
                relayerLib: address(0),
                validatorLibs: new address[](0),
                validatorConfigs: new bytes[](0),
                relayerConfig: new bytes(0),
                dstChainData: MessageCodec.encodeEvmDstChainData(address(s_relayerLib), gasLimit),
                payload: "Test message"
            });
    }
}
