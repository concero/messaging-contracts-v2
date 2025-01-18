// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

error NotAContract(address target);
error DelegateCallFailed(bytes response);

library Utils {
    function safeDelegateCall(address target, bytes memory args) internal returns (bytes memory) {
        require(isContract(target), NotAContract(target));

        (bool success, bytes memory response) = target.delegatecall(args);
        if (!success) {
            revert DelegateCallFailed(response);
        }

        return response;
    }

    /**
     * @notice Checks if the provided address is a contract.
     * @param addr The address to check.
     * @return bool True if the address is a contract, false otherwise.
     */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}
