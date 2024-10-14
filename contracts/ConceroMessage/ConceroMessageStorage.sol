pragma solidity 0.8.20;

contract ConceroMessageStorage {
    mapping(uint64 dstChainSelector => bool isSupported) internal s_supportedChainSelectors;
}
