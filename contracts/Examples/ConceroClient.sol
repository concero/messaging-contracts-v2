pragma solidity 0.8.28;

import {ConceroReceiver} from "../ConceroReceiver/ConceroReceiver.sol";

contract ConceroClient is ConceroReceiver {
    event Received(bytes32 messageId, Message message);

    constructor(address conceroRouter) ConceroReceiver(conceroRouter) {}

    function _conceroReceive(bytes32 messageId, Message calldata message) internal override {
        emit Received(messageId, message);
    }
}
