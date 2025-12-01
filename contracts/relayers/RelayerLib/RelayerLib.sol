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
import {Base} from "contracts/common/Base.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {IRelayer} from "contracts/interfaces/IRelayer.sol";
import {IRelayerLib} from "contracts/interfaces/IRelayerLib.sol";
import {MessageCodec} from "../../common/libraries/MessageCodec.sol";
import {ValidatorCodec} from "../../common/libraries/ValidatorCodec.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/// @title RelayerLib
/// @notice Concero relayer library responsible for pricing message delivery and managing allowed relayers.
/// @dev
/// - Implements `IRelayerLib` used by the ConceroRouter to:
///   * calculate the native fee required to deliver a message on the destination chain,
///   * validate that a given relayer is allowed to submit messages,
///   * indicate supported fee tokens.
/// - Uses AccessControl for admin operations and a Concero price feed via `Base`.
contract RelayerLib is AccessControlUpgradeable, IRelayerLib, Base {
    using SafeERC20 for IERC20;
    using ValidatorCodec for bytes;

    uint256 internal constant DECIMALS = 1e18;
    bytes32 internal constant ADMIN = keccak256("ADMIN");

    IRelayer internal immutable i_conceroRouter;

    // STORAGE VARS //

    /// @dev relayer lib vars
    uint32 internal s_submitMsgGasOverhead;
    /// @dev relayer lib mappings
    mapping(address relayer => bool isAllowed) internal s_isAllowedRelayer;

    constructor(
        uint24 chainSelector,
        address conceroPriceFeed,
        address conceroRouter
    ) AccessControlUpgradeable() Base(chainSelector, conceroPriceFeed) {
        i_conceroRouter = IRelayer(conceroRouter);
    }

    receive() external payable {}

    // INITIALIZER //

    function initialize(address admin) public initializer {
        _setRoleAdmin(ADMIN, DEFAULT_ADMIN_ROLE);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN, admin);
    }

    // VIEW FUNCTIONS //

    /// @inheritdoc IRelayerLib
    function getFee(
        IConceroRouter.MessageRequest calldata messageRequest,
        bytes[] calldata validatorConfigs
    ) external view returns (uint256) {
        uint32 totalValidatorGasLimit = _getTotalValidatorsGasLimit(validatorConfigs);

        (uint256 dstNativeRate, uint256 dstGasPrice) = i_conceroPriceFeed
            .getNativeNativeRateAndGasPrice(messageRequest.dstChainSelector);
        (, uint32 gasLimit) = MessageCodec.decodeEvmDstChainData(messageRequest.dstChainData);

        return
            (dstGasPrice *
                uint256(s_submitMsgGasOverhead + gasLimit + totalValidatorGasLimit) *
                dstNativeRate) / DECIMALS;
    }

    /// @inheritdoc IRelayerLib
    /// @dev
    /// - Simply checks that the given `relayer` is marked as allowed.
    /// - Reverts with `InvalidRelayer(relayer)` if the relayer is not authorized.
    function validate(bytes calldata /* messageReceipt */, address relayer) external view {
        require(s_isAllowedRelayer[relayer], InvalidRelayer(relayer));
    }

    // @notice Returns whether a given relayer address is allowed by this relayer library.
    /// @param relayer Address of the relayer to check.
    /// @return True if the relayer is allowed, false otherwise.
    function isAllowedRelayer(address relayer) external view returns (bool) {
        return s_isAllowedRelayer[relayer];
    }

    /// @inheritdoc IRelayerLib
    function isFeeTokenSupported(address feeToken) public pure returns (bool) {
        return feeToken == address(0);
    }

    /* Setters */

    /// @notice Batch updates the allowlist of relayers.
    /// @dev
    /// - Callable only by accounts with the `ADMIN` role.
    /// - `relayers` and `isAllowed` arrays must have the same length.
    /// @param relayers Addresses of relayers to update.
    /// @param isAllowed Corresponding flags indicating whether each relayer is allowed.
    function setRelayers(
        address[] calldata relayers,
        bool[] calldata isAllowed
    ) external onlyRole(ADMIN) {
        require(relayers.length == isAllowed.length, CommonErrors.LengthMismatch());

        for (uint256 i = 0; i < relayers.length; i++) {
            s_isAllowedRelayer[relayers[i]] = isAllowed[i];
        }
    }

    /// @notice Sets the base gas overhead for `submitMessage` on the destination chain.
    /// @dev
    /// - Callable only by accounts with the `ADMIN` role.
    /// - `submitMsgGasOverhead` must be greater than zero.
    /// @param submitMsgGasOverhead New gas overhead value to use in fee calculations.
    function setSubmitMsgGasOverhead(uint32 submitMsgGasOverhead) external onlyRole(ADMIN) {
        require(submitMsgGasOverhead > 0, CommonErrors.InvalidAmount());
        s_submitMsgGasOverhead = submitMsgGasOverhead;
    }

    /* Withdraw fees */

    /// @notice Withdraws relayer fees accrued in the Concero router and forwards them to the admin.
    /// @dev
    /// - Callable only by accounts with the `ADMIN` role.
    /// - Steps:
    ///   1. Calls `withdrawRelayerFee` on the Concero router (as `IRelayer`),
    ///      pulling fees owed to this relayer lib.
    ///   2. For each token in `tokens`:
    ///      * For native token (address(0)), sends the entire ETH balance to `msg.sender`.
    ///      * For ERC-20 tokens, transfers the entire token balance to `msg.sender`.
    /// @param tokens Array of fee tokens to withdraw (use address(0) for native token).
    function withdrawRelayerFee(address[] calldata tokens) external onlyRole(ADMIN) {
        i_conceroRouter.withdrawRelayerFee(tokens);

        for (uint256 i = 0; i < tokens.length; ++i) {
            if (tokens[i] == address(0)) {
                Address.sendValue(payable(msg.sender), address(this).balance);
            } else {
                uint256 tokenBalance = IERC20(tokens[i]).balanceOf(address(this));

                if (tokenBalance > 0) {
                    IERC20(tokens[i]).safeTransfer(msg.sender, tokenBalance);
                }
            }
        }
    }

    // INTERNAL FUNCTIONS //

    /// @notice Computes the total EVM gas limit required by all validators.
    /// @dev
    /// - Each `validatorConfigs[i]` is expected to be an EVM config encoded via `ValidatorCodec`.
    /// - Reverts with `InvalidOperatorConfigType` if any config is not of type `EVM`.
    /// @param validatorConfigs Array of validator configuration blobs.
    /// @return totalGasLimit Sum of gas limits from all EVM validator configs.
    function _getTotalValidatorsGasLimit(
        bytes[] calldata validatorConfigs
    ) internal pure returns (uint32) {
        uint32 totalGasLimit;

        for (uint256 i; i < validatorConfigs.length; ++i) {
            require(
                validatorConfigs[i].configType() == ValidatorCodec.ConfigType.EVM,
                InvalidOperatorConfigType(uint8(validatorConfigs[i].configType()))
            );

            totalGasLimit += validatorConfigs[i].evmConfig();
        }

        return totalGasLimit;
    }
}
