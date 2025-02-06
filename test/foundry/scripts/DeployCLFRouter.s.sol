pragma solidity 0.8.28;

import "../../../contracts/mocks/MockCLFRouter.sol";
import {Script} from "forge-std/src/Script.sol";

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
