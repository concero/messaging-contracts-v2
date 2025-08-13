// SPDX-License-Identifier: MIT
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroClient} from "../ConceroClient/ConceroClient.sol";

enum ErrorType {
    EmptyRevert,
    StringRevert,
    PanicRevert,
    CustomErrorRevert,
    OutOfGasRevert
}

contract ConceroClientRevertMock is ConceroClient {
    bool public s_isRevertMode;

    event MessageReceived(bytes32 messageId, bytes message);
    error CustomConceroError(uint256 code, string reason);

    constructor(address conceroRouter) ConceroClient(conceroRouter) {
        s_isRevertMode = true;
    }

    function _conceroReceive(
        bytes32 messageId,
        uint24 /** */,
        bytes calldata /** */,
        bytes calldata message
    ) internal override {
        uint8 errorType = abi.decode(message, (uint8));

        if (!s_isRevertMode) {
            emit MessageReceived(messageId, message);
            return;
        }

        if (errorType == uint8(ErrorType.EmptyRevert)) {
            // solhint-disable-next-line gas-custom-errors, reason-string
            revert();
        } else if (errorType == uint8(ErrorType.StringRevert)) {
            // solhint-disable-next-line gas-custom-errors
            revert("ConceroClientRevertMock: String revert message");
        } else if (errorType == uint8(ErrorType.PanicRevert)) {
            assert(false);
        } else if (errorType == uint8(ErrorType.CustomErrorRevert)) {
            revert CustomConceroError(42, "Custom error with parameters");
        } else if (errorType == uint8(ErrorType.OutOfGasRevert)) {
            uint256 currentAvailableGas = gasleft();
            uint256 iterations = (currentAvailableGas / 20_000) * 2;

            // solhint-disable-next-line no-inline-assembly
            assembly {
                for {
                    let i := 0
                } lt(i, iterations) {
                    i := add(i, 1)
                } {
                    sstore(i, i) // each new slot -> 20_000 gas (5 iterations => 100_000)
                }
            }
        }

        emit MessageReceived(messageId, message);
    }

    function setRevertMode(bool mode) external {
        s_isRevertMode = mode;
    }
}
