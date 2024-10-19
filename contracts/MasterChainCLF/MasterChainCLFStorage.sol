pragma solidity 0.8.28;

import {IMasterChainCLF} from "./Interfaces/IMasterChainCLF.sol";

contract MasterChainCLFStorage is IMasterChainCLF {
    mapping(address operator => bool isAllowed) internal s_isAllowedOperators;
    mapping(bytes32 conceroMessageId => CLFRequestStatus status)
        internal s_clfRequestStatusByConceroId;
}
