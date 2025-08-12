// SPDX-License-Identifier: UNLICENSED
// solhint-disable func-param-name-mixedcase
// solhint-disable func-name-mixedcase

pragma solidity 0.8.28;

import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {ConceroVerifier} from "contracts/ConceroVerifier/ConceroVerifier.sol";
import {CLFParams} from "contracts/ConceroVerifier/libraries/Types.sol";
import {Utils} from "contracts/ConceroVerifier/libraries/Utils.sol";
import {Storage as s} from "contracts/ConceroVerifier/libraries/Storage.sol";

contract ConceroVerifierHarness is ConceroVerifier {
    using s for s.Operator;

    constructor(
        uint24 chainSelector,
        address USDC,
        address conceroPriceFeed,
        CLFParams memory clfParams
    ) ConceroVerifier(chainSelector, USDC, conceroPriceFeed, clfParams) {}

    function exposed_operatorRegistration(
        CommonTypes.ChainType chainType,
        address operatorAddress,
        bool isRegistered
    ) external returns (bytes32 clfRequestId) {
        if (isRegistered) {
            Utils._addOperator(chainType, abi.encodePacked(operatorAddress));
            s.operator().isRegistered[operatorAddress] = true;
        } else {
            Utils._removeOperator(chainType, abi.encodePacked(operatorAddress));
            s.operator().isRegistered[operatorAddress] = false;
        }
    }
}
