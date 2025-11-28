// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IValidatorLib} from "../../interfaces/IValidatorLib.sol";

abstract contract EcdsaValidatorLib is IValidatorLib {
    using ECDSA for bytes32;

    error InvalidSignaturesCount(uint256 received, uint256 expected);
    error DuplicateSigner(address signer);
    error InvalidSigner(address signer);
    error InvalidSignersCount(uint256 signersCount, uint256 isAllowedArrLength);

    mapping(address signer => bool isAllowed) internal s_isSignerAllowed;
    uint8 internal s_expectedSignersCount;
    uint256[50] private __gap;

    function isValid(
        bytes calldata messageReceipt,
        bytes calldata validation
    ) external view override returns (bool) {
        _verifySignatures(validation);
        return _checkValidation(messageReceipt, validation);
    }

    function isSignerAllowed(address signer) external view returns (bool) {
        return s_isSignerAllowed[signer];
    }

    function getExpectedSignersCount() external view returns (uint8) {
        return s_expectedSignersCount;
    }

    // INTERNAL FUNCTIONS

    function _verifySignatures(bytes calldata validation) internal view {
        (bytes[] memory signatures, bytes32 hash) = _extractSignaturesAndHash(validation);

        require(
            signatures.length == s_expectedSignersCount,
            InvalidSignaturesCount(signatures.length, s_expectedSignersCount)
        );

        address[] memory signers = new address[](signatures.length);

        for (uint256 i; i < signatures.length; ++i) {
            address signer = _recoverSignature(signatures[i], hash);
            require(s_isSignerAllowed[signer], InvalidSigner(signer));
            for (uint256 k; k < signers.length; ++k) {
                require(signer != signers[k], DuplicateSigner(signer));
            }
            signers[i] = signer;
        }
    }

    function _recoverSignature(
        bytes memory signature,
        bytes32 hash
    ) internal pure virtual returns (address) {
        signature[signature.length - 1] = bytes1(uint8(signature[signature.length - 1]) + 27);
        return hash.recover(signature);
    }

    function _setAllowedSigners(address[] calldata signers, bool[] calldata isAllowedArr) internal {
        require(
            signers.length == isAllowedArr.length,
            InvalidSignersCount(signers.length, isAllowedArr.length)
        );

        for (uint256 i; i < signers.length; ++i) {
            s_isSignerAllowed[signers[i]] = isAllowedArr[i];
        }
    }

    function _setExpectedSignersCount(uint8 expectedSignersCount) internal {
        s_expectedSignersCount = expectedSignersCount;
    }

    function _extractSignaturesAndHash(
        bytes calldata validation
    ) internal view virtual returns (bytes[] memory, bytes32);

    function _checkValidation(
        bytes calldata messageReceipt,
        bytes calldata validation
    ) internal view virtual returns (bool);
}
