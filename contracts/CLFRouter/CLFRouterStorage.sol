pragma solidity 0.8.28;

import {ICLFRouter} from "./Interfaces/ICLFRouter.sol";

contract CLFRouterStorage is ICLFRouter {
    mapping(address operator => bool isAllowed) internal s_isAllowedOperator;
    mapping(bytes32 conceroMessageId => CLFRequestStatus status)
        internal s_clfRequestStatusByConceroId;
}
