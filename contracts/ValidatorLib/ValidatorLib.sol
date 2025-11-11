// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Decoder as DecoderLib} from "contracts/common/libraries/Decoder.sol";
import {Utils as CommonUtils} from "contracts/common/libraries/Utils.sol";
import {CommonConstants} from "contracts/common/CommonConstants.sol";
import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {CommonTypes} from "contracts/common/CommonTypes.sol";
import {Base} from "contracts/common/Base.sol";
import {IConceroRouter} from "../interfaces/IConceroRouter.sol";

import {IValidatorLib} from "contracts/interfaces/IValidatorLib.sol";
import {Types} from "./libraries/Types.sol";

import {Storage as s} from "./libraries/Storage.sol";
import {ClfSigner} from "./modules/ClfSigner.sol";

contract ValidatorLib is IValidatorLib, Base, ClfSigner {
    using s for s.ValidatorLib;

    uint8 internal constant VALIDATOR_LIB_FEE_BPS_USD = 100;

    constructor(
        uint24 chainSelector,
        address conceroPriceFeed,
        address conceroValidator,
        uint64 conceroValidatorSubId,
        address[4] memory clfSigners
    )
        Base(chainSelector, conceroPriceFeed)
        ClfSigner(conceroValidator, conceroValidatorSubId, clfSigners)
    {}

    function setDstLib(uint24 dstChainSelector, address dstLib) external onlyOwner {
        require(dstChainSelector != i_chainSelector, InvalidChainSelector());

        s.validatorLib().dstLibs[dstChainSelector] = abi.encode(dstLib);
    }

    /* Getters */

    // TODO: add messageReceipt hash check!
    function isValid(bytes calldata, bytes calldata validation) external view returns (bool) {
        (Types.ClfDonReportSubmission memory reportSubmission, uint256 index) = abi.decode(
            validation,
            (Types.ClfDonReportSubmission, uint256)
        );

        // Verify CLF report signatures
        if (!_isValidClfReportSignatures(reportSubmission)) {
            return false;
        }

        // Decode CLF report
        Types.ClfReport memory clfReport = DecoderLib._decodeCLFReportMemory(
            reportSubmission.report
        );

        // Check index bounds
        if (index >= clfReport.onchainMetadata.length || index >= clfReport.results.length) {
            return false;
        }

        // Check onchain metadata
        Types.ClfReportOnchainMetadata memory onchainMetadata = abi.decode(
            clfReport.onchainMetadata[index],
            (Types.ClfReportOnchainMetadata)
        );

        if (!_isValidClfReportOnChainMetadata(onchainMetadata)) {
            return false;
        }

        // Check if the message and dstChainSelector are valid
        (CommonTypes.ResultConfig memory resultConfig, bytes memory payload) = DecoderLib
            ._decodeVerifierResult(clfReport.results[index]);

        CommonTypes.MessagePayloadV1 memory messagePayload = abi.decode(
            payload,
            (CommonTypes.MessagePayloadV1)
        );

        if (resultConfig.payloadVersion == 1) {
            if (messagePayload.dstChainSelector != i_chainSelector) {
                return false;
            }
            return true;
        }

        return false;
    }

    function getFee(IConceroRouter.MessageRequest calldata) external view returns (uint256) {
        (uint256 nativeUsdRate, ) = i_conceroPriceFeed.getNativeUsdRateAndGasPrice();

        require(
            nativeUsdRate > 0,
            CommonErrors.RequiredVariableUnset(CommonErrors.RequiredVariableUnsetType.NativeUSDRate)
        );

        uint256 validatorLibFee = CommonUtils.convertUsdBpsToNative(
            VALIDATOR_LIB_FEE_BPS_USD,
            nativeUsdRate
        );

        return validatorLibFee;
    }

    function getDstLib(uint24 dstChainSelector) external view returns (bytes memory) {
        return s.validatorLib().dstLibs[dstChainSelector];
    }
}
