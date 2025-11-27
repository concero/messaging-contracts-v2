// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {Utils} from "contracts/common/libraries/Utils.sol";
import {Base} from "contracts/common/Base.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {IRelayer} from "contracts/interfaces/IRelayer.sol";
import {IRelayerLib} from "contracts/interfaces/IRelayerLib.sol";
import {RelayerLibStorage} from "./RelayerLibStorage.sol";
import {MessageCodec} from "../../common/libraries/MessageCodec.sol";

contract RelayerLib is IRelayerLib, RelayerLibStorage, Base {
    using SafeERC20 for IERC20;

    uint256 internal constant DECIMALS = 1e18;

    IRelayer internal immutable i_conceroRouter;

    constructor(
        uint24 chainSelector,
        address conceroPriceFeed,
        address conceroRouter
    ) RelayerLibStorage() Base(chainSelector, conceroPriceFeed) {
        i_conceroRouter = IRelayer(conceroRouter);
    }

    receive() external payable {}

    function getFee(
        IConceroRouter.MessageRequest calldata messageRequest
    ) external view returns (uint256) {
        (uint256 dstNativeRate, uint256 dstGasPrice) = i_conceroPriceFeed
            .getNativeNativeRateAndGasPrice(messageRequest.dstChainSelector);

        (, uint32 gasLimit) = MessageCodec.decodeEvmDstChainData(messageRequest.dstChainData);

        return
            (dstGasPrice * uint256(s_submitMsgGasOverhead + gasLimit) * dstNativeRate) / DECIMALS;
    }

    function validate(bytes calldata /* messageReceipt */, address relayer) external view {
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

    function setSubmitMsgGasOverhead(uint32 submitMsgGasOverhead) external onlyOwner {
        require(submitMsgGasOverhead > 0, CommonErrors.InvalidAmount());
        s_submitMsgGasOverhead = submitMsgGasOverhead;
    }

    /* Withdraw fees */

    function withdrawRelayerFee(address[] calldata tokens) external onlyOwner {
        i_conceroRouter.withdrawRelayerFee(tokens);

        for (uint256 i = 0; i < tokens.length; ++i) {
            if (tokens[i] == address(0)) {
                Utils.transferNative(msg.sender, address(this).balance);
            } else {
                uint256 tokenBalance = IERC20(tokens[i]).balanceOf(address(this));

                if (tokenBalance > 0) {
                    IERC20(tokens[i]).safeTransfer(msg.sender, tokenBalance);
                }
            }
        }
    }
}
