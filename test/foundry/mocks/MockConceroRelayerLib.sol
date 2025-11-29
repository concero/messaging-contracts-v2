// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IRelayerLib} from "../../../contracts/interfaces/IRelayerLib.sol";
import {IConceroRouter} from "../../../contracts/interfaces/IConceroRouter.sol";

contract MockConceroRelayerLib is IRelayerLib {
    uint256 internal s_relayerFeeInNative = 0.001 ether;

    function getFee(
        IConceroRouter.MessageRequest calldata,
        bytes[] calldata
    ) external view returns (uint256) {
        return s_relayerFeeInNative;
    }

    function validate(bytes calldata, address) external {}

    function setRelayerFeeInNative(uint256 fee) external {
        s_relayerFeeInNative = fee;
    }

    function isFeeTokenSupported(address) public pure returns (bool) {
        return true;
    }

    receive() external payable {}
}
