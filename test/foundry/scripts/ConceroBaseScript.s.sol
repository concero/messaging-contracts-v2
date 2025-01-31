pragma solidity 0.8.28;

import {Script} from "forge-std/src/Script.sol";

abstract contract ConceroBaseScript is Script {
    address public immutable deployer;
    address public immutable proxyDeployer;

    address public constant operator = address(0x1);
    address public constant nonOperator = address(0x2);
    address public constant user = address(0x123);

    uint24 public constant chainSelector = 8453;

    constructor() {
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        proxyDeployer = vm.envAddress("PROXY_DEPLOYER_ADDRESS");
    }
}
