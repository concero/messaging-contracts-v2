// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

abstract contract ValidatorLibStorage {
    mapping(uint24 dstChainSelector => bytes dstLib) internal s_dstLibs;
}
