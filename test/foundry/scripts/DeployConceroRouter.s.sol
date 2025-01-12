// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {DeployHelper} from "../utils/DeployHelper.sol";
import {ConceroRouter} from "contracts/ConceroRouter/ConceroRouter.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "contracts/Proxy/TransparentUpgradeableProxy.sol";
import {Script} from "forge-std/src/Script.sol";
import {console} from "forge-std/src/console.sol";
import {PauseDummy} from "../../../contracts/PauseDummy/PauseDummy.sol";

contract DeployConceroRouter is DeployHelper {
    TransparentUpgradeableProxy internal conceroRouterProxy;
    ConceroRouter internal conceroRouter;

    address public proxyDeployer = vm.envAddress("PROXY_DEPLOYER_ADDRESS");
    address public deployer = vm.envAddress("DEPLOYER_ADDRESS");
    uint24 public chainSelector = uint24(1);

    function run() public returns (address) {
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
        conceroRouter = new ConceroRouter(chainSelector);
        vm.stopPrank();

        setProxyImplementation(address(conceroRouter));
    }
}
