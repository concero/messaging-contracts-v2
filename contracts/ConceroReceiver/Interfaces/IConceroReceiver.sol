pragma solidity 0.8.28;

import {IMessage} from "../../Common/IMessage.sol";

interface IConceroReceiver is IMessage {
    function conceroReceive(bytes32 messageId, Message calldata message) external;
}
