// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library Namespaces {
    bytes32 internal constant VALIDATOR_LIB =
        keccak256(
            abi.encode(uint256(keccak256(abi.encodePacked("validator.library.storage"))) - 1)
        ) & ~bytes32(uint256(0xff));
}

library Storage {
    struct ValidatorLib {
        mapping(uint24 dstChainSelector => bytes dstLib) dstLibs;
    }

    /* SLOT-BASED STORAGE ACCESS */
    function validatorLib() internal pure returns (ValidatorLib storage s) {
        bytes32 slot = Namespaces.VALIDATOR_LIB;
        assembly {
            s.slot := slot
        }
    }
}
