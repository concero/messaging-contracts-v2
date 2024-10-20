pragma solidity 0.8.28;

import {IMessage} from "../../Common/IMessage.sol";

interface IConceroMessageClient {
    function conceroMessageReceive(bytes32 messageId, IMessage.Message calldata message) external;
}
