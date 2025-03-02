// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Script} from "forge-std/src/Script.sol";

import {MockCLFRouter} from "contracts/mocks/MockCLFRouter.sol";

contract DeployMockCLFRouter is Script {
    MockCLFRouter public mockRouter;

    function run() public returns (address) {
        mockRouter = new MockCLFRouter();
        return address(mockRouter);
    }

    function run(uint256 forkId) public returns (address) {
        vm.selectFork(forkId);
        return run();
    }
}
