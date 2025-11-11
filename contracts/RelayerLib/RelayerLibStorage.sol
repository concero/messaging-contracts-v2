// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

abstract contract RelayerLibStorage {
    /// @dev relayer lib vars
    uint32 internal s_submitMsgGasOverhead;

    /// @dev relayer lib mappings
    mapping(uint24 dstChainSelector => address dstLib) internal s_dstLibs;
    mapping(address relayer => bool isAllowed) internal s_isAllowedRelayer;
}
