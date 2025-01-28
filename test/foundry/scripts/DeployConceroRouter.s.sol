// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ConceroRouter} from "contracts/ConceroRouter/ConceroRouter.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "contracts/Proxy/TransparentUpgradeableProxy.sol";
import {PauseDummy} from "../../../contracts/PauseDummy/PauseDummy.sol";
import {DeployERC20, MockERC20} from "./DeployERC20.s.sol";
import {ConceroBaseScript} from "../utils/ConceroTest.sol";

contract DeployConceroRouter is ConceroBaseScript {
    TransparentUpgradeableProxy internal conceroRouterProxy;
    ConceroRouter internal conceroRouter;

    address public USDC;

    function run() public returns (address) {
        DeployERC20 tokenDeployer = new DeployERC20();
        USDC = address(tokenDeployer.deployERC20("USD Coin", "USDC", 6));

        _deployConceroRouter();
        return address(conceroRouterProxy);
    }

    function run(uint256 forkId) public returns (address) {
        vm.selectFork(forkId);
        return run();
    }

    function setProxyImplementation(address implementation) public {
        vm.startPrank(proxyDeployer);
        ITransparentUpgradeableProxy(address(conceroRouterProxy)).upgradeToAndCall(
            implementation,
            bytes("")
        );
        vm.stopPrank();
    }

    function getProxy() public view returns (address) {
        return address(conceroRouterProxy);
    }

    function _deployConceroRouter() internal {
        _deployConceroRouterProxy();
        _deployAndSetImplementation();
    }

    function _deployConceroRouterProxy() internal {
        vm.startPrank(proxyDeployer);
        conceroRouterProxy = new TransparentUpgradeableProxy(
            address(new PauseDummy()),
            proxyDeployer,
            ""
        );
        vm.stopPrank();
    }

    function _deployAndSetImplementation() internal {
        vm.startPrank(deployer);
        conceroRouter = new ConceroRouter(chainSelector, USDC);
        vm.stopPrank();

        setProxyImplementation(address(conceroRouter));
    }
}
