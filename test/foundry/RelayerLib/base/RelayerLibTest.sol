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

abstract contract RelayerLibTest is ConceroTest {
    RelayerLib internal relayerLib;

    function setUp() public virtual {
        relayerLib = new RelayerLib(SRC_CHAIN_SELECTOR, address(s_conceroPriceFeed));
		relayerLib.setSubmitMsgGasOverhead(SUBMIT_MSG_GAS_OVERHEAD);
    }

    function _createMessageRequest(
        uint24 dstChainSelector,
        uint32 gasLimit
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
                dstChainData: MessageCodec.encodeEvmDstChainData(address(0), gasLimit),
                payload: "Test message"
            });
    }
}
