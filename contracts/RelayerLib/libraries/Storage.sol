// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library Namespaces {
    bytes32 internal constant RELAYER_LIB =
        keccak256(abi.encode(uint256(keccak256(abi.encodePacked("relayer.library.storage"))) - 1)) &
            ~bytes32(uint256(0xff));
}

library Storage {
    struct RelayerLib {
        mapping(uint24 dstChainSelector => address dstLib) dstLibs;
        mapping(address relayer => bool isAllowed) isAllowedRelayer;
    }

    /* SLOT-BASED STORAGE ACCESS */
    function relayerLib() internal pure returns (RelayerLib storage s) {
        bytes32 slot = Namespaces.RELAYER_LIB;
        assembly {
            s.slot := slot
        }
    }
}
