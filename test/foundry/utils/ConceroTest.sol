pragma solidity 0.8.28;

import {Script} from "forge-std/src/Script.sol";
import {Test} from "forge-std/src/Test.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ConceroTest is Test {
    using SafeERC20 for IERC20;

    address public deployer;
    address public proxyDeployer;
    address public operator;
    address public nonOperator;
    address public user;
    address public usdc;

    function setUp() public virtual {
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        proxyDeployer = vm.envAddress("PROXY_DEPLOYER_ADDRESS");
        operator = address(0x1);
        nonOperator = address(0x2);
        user = address(0x123);
    }
}
