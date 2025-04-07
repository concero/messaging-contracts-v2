// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Storage as s} from "../libraries/Storage.sol";
import {CommonErrors} from "../../common/CommonErrors.sol";

import {Base} from "./Base.sol";

abstract contract SupportedChains is Base {
    using s for s.Verifier;

    error UnsupportedChainSelector();

    function isChainSupported(uint24 chainSelector) public view returns (bool) {
        return s.verifier().isChainSupported[chainSelector];
    }

    /**
     * @notice Set support status for multiple chains at once
     * @param chainSelectors Array of chain selectors to update
     * @param isSupported Array of boolean values indicating support status for each corresponding chain selector
     */
    function setSupportedChains(
        uint24[] calldata chainSelectors,
        bool[] calldata isSupported
    ) external onlyOwner {
        require(chainSelectors.length == isSupported.length, CommonErrors.LengthMismatch());

        for (uint256 index = 0; index < chainSelectors.length; index++) {
            uint24 chainSelector = chainSelectors[index];
            bool supported = isSupported[index];

            s.verifier().isChainSupported[chainSelector] = supported;

            if (supported) {
                s.verifier().supportedChainSelectors.push(chainSelector);
            } else {
                uint256 length = s.verifier().supportedChainSelectors.length;
                for (uint256 i = 0; i < length; i++) {
                    if (s.verifier().supportedChainSelectors[i] == chainSelector) {
                        if (i < length - 1) {
                            s.verifier().supportedChainSelectors[i] = s.verifier().supportedChainSelectors[length - 1];
                        }
                        s.verifier().supportedChainSelectors.pop();
                        break;
                    }
                }
            }
        }
    }

    function getSupportedChains() public view returns (uint24[] memory) {
        uint24[] memory supportedChains = new uint24[](s.verifier().supportedChainSelectors.length);
        for (uint256 i = 0; i < s.verifier().supportedChainSelectors.length; i++) {
            supportedChains[i] = s.verifier().supportedChainSelectors[i];
        }
        return supportedChains;
    }

}
