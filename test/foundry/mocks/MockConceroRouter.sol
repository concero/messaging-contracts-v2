// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";

contract MockConceroRouter is IConceroRouter {
    error InvalidFeeValue();

	uint256 internal s_messageFee = 0.0001 ether;

    function conceroSend(
        MessageRequest calldata messageRequest
    ) external payable returns (bytes32 messageId) {
        require(msg.value == _getFee(), InvalidFeeValue());

        return keccak256(abi.encode(messageRequest));
    }

    function getMessageFee(
        MessageRequest calldata /** messageRequest */
    ) external view returns (uint256) {
        return _getFee();
    }

    function _getFee() internal view returns (uint256) {
        return s_messageFee;
    }
}
