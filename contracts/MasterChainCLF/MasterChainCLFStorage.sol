pragma solidity 0.8.20;

import {IMasterChainCLFStorage} from "./Interfaces/IMasterChainCLFStorage.sol";

contract MasterChainCLFStorage is IMasterChainCLFStorage {
    mapping(address operator => bool isAllowed) internal s_isAllowedOperators;
    mapping(bytes32 conceroMessageId => CLFRequestStatus status)
        internal s_clfRequestStatusByConceroId;
}
