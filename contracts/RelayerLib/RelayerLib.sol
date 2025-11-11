// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {BytesUtils} from "contracts/common/libraries/BytesUtils.sol";
import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {Base} from "contracts/common/Base.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {IRelayerLib} from "contracts/interfaces/IRelayerLib.sol";
import {RelayerLibStorage} from "./RelayerLibStorage.sol";

contract RelayerLib is IRelayerLib, RelayerLibStorage, Base {
    uint256 internal constant DECIMALS = 1e18;

    constructor(
        uint24 chainSelector,
        address conceroPriceFeed
    ) Base(chainSelector, conceroPriceFeed) {}

    function getFee(
        IConceroRouter.MessageRequest calldata messageRequest
    ) external view returns (uint256) {
        (uint256 dstNativeRate, uint256 dstGasPrice) = i_conceroPriceFeed
            .getNativeNativeRateAndGasPrice(messageRequest.dstChainSelector);

        uint32 gasLimit = BytesUtils.readUint32(messageRequest.dstChainData, 20);

        return
            (dstGasPrice * uint256(s_submitMsgGasOverhead + gasLimit) * dstNativeRate) / DECIMALS;
    }

    function getDstLib(uint24 dstChainSelector) external view returns (bytes memory) {
        return s_dstLibs[dstChainSelector];
    }

    function validate(bytes calldata /* messageReceipt */, address relayer) external {
        if (!s_isAllowedRelayer[relayer]) {
            revert InvalidRelayer();
        }
    }

    function isAllowedRelayer(address relayer) external view returns (bool) {
        return s_isAllowedRelayer[relayer];
    }

    /* Setters */

    function setRelayers(
        address[] calldata relayers,
        bool[] calldata isAllowed
    ) external onlyOwner {
        require(relayers.length == isAllowed.length, CommonErrors.LengthMismatch());

        for (uint256 i = 0; i < relayers.length; i++) {
            s_isAllowedRelayer[relayers[i]] = isAllowed[i];
        }
    }

    function setDstLibs(
        uint24[] calldata dstChainSelectors,
        address[] calldata dstLibs
    ) external onlyOwner {
        require(dstChainSelectors.length == dstLibs.length, CommonErrors.LengthMismatch());

        for (uint256 i = 0; i < dstChainSelectors.length; i++) {
            s_dstLibs[dstChainSelectors[i]] = abi.encode(dstLibs[i]);
        }
    }

    function setSubmitMsgGasOverhead(uint32 submitMsgGasOverhead) external onlyOwner {
        require(submitMsgGasOverhead > 0, CommonErrors.InvalidAmount());
        s_submitMsgGasOverhead = submitMsgGasOverhead;
    }
}
