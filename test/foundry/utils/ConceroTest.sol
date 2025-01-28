pragma solidity 0.8.28;

import {Script} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

abstract contract ConceroTest is Test, ConceroBaseScript {
    address public usdc;
}
