// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {BytesUtils} from "contracts/common/libraries/BytesUtils.sol";
import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {IRelayerLib} from "contracts/interfaces/IRelayerLib.sol";

import {Storage as s} from "./libraries/Storage.sol";
import {Base} from "./modules/Base.sol";

contract RelayerLib is IRelayerLib, Base {
    using s for s.RelayerLib;

    uint256 internal constant DECIMALS = 1e18;
    uint32 internal s_submitMsgGasOverhead;

    constructor(
        uint24 chainSelector,
        address conceroPriceFeed,
        uint32 submitMsgGasOverhead
    ) Base(chainSelector, conceroPriceFeed) {
        require(submitMsgGasOverhead > 0, CommonErrors.InvalidAmount());

        s_submitMsgGasOverhead = submitMsgGasOverhead;
    }

    function getFee(
        IConceroRouter.MessageRequest calldata messageRequest
    ) external view returns (uint256) {
        (, uint256 dstGasPrice, uint256 dstNativeRate, , ) = i_conceroPriceFeed.getMessageFeeData(
            messageRequest.dstChainSelector,
            0
        );

        require(
            dstGasPrice > 0,
            CommonErrors.RequiredVariableUnset(CommonErrors.RequiredVariableUnsetType.DstGasPrice)
        );
        require(
            dstNativeRate > 0,
            CommonErrors.RequiredVariableUnset(CommonErrors.RequiredVariableUnsetType.DstNativeRate)
        );

        uint32 gasLimit = BytesUtils.readUint32(messageRequest.dstChainData, 20);

        return
            (dstGasPrice * uint256(s_submitMsgGasOverhead + gasLimit) * dstNativeRate) / DECIMALS;
    }

    function getDstLib(uint24 dstChainSelector) external view returns (bytes memory) {
        return abi.encode(s.relayerLib().dstLibs[dstChainSelector]);
    }

    function validate(bytes calldata /* messageReceipt */, address relayer) external {
        if (!s.relayerLib().isAllowedRelayer[relayer]) {
            revert InvalidRelayer();
        }
    }

    function isAllowedRelayer(address relayer) external view returns (bool) {
        return s.relayerLib().isAllowedRelayer[relayer];
    }

    /* Setters */

    function setRelayers(
        address[] calldata relayers,
        bool[] calldata isAllowed
    ) external onlyOwner {
        require(relayers.length == isAllowed.length, CommonErrors.LengthMismatch());

        s.RelayerLib storage s_relayerLib = s.relayerLib();

        for (uint256 i = 0; i < relayers.length; i++) {
            s_relayerLib.isAllowedRelayer[relayers[i]] = isAllowed[i];
        }
    }

    function setDstLibs(
        uint24[] calldata dstChainSelectors,
        address[] calldata dstLibs
    ) external onlyOwner {
        require(dstChainSelectors.length == dstLibs.length, CommonErrors.LengthMismatch());

        s.RelayerLib storage s_relayerLib = s.relayerLib();

        for (uint256 i = 0; i < dstChainSelectors.length; i++) {
            s_relayerLib.dstLibs[dstChainSelectors[i]] = dstLibs[i];
        }
    }

    function setSubmitMsgGasOverhead(uint32 submitMsgGasOverhead) external onlyOwner {
        require(submitMsgGasOverhead > 0, CommonErrors.InvalidAmount());
        s_submitMsgGasOverhead = submitMsgGasOverhead;
    }
}
