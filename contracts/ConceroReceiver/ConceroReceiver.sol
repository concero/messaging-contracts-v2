pragma solidity 0.8.28;

import {IConceroReceiver} from "./Interfaces/IConceroReceiver.sol";

error InvalidRouter(address router);

abstract contract ConceroReceiver is IConceroReceiver {
    address internal immutable i_conceroRouter;

    modifier onlyRouter() {
        if (msg.sender != address(i_conceroRouter)) {
            revert InvalidRouter(msg.sender);
        }
        _;
    }

    constructor(address router) {
        if (router == address(0)) {
            revert InvalidRouter(address(0));
        }
        i_conceroRouter = router;
    }

    function conceroReceive(bytes32 messageId, Message calldata message) external onlyRouter {
        _conceroReceive(messageId, message);
    }

    function _conceroReceive(bytes32 messageId, Message calldata message) internal virtual;
}
