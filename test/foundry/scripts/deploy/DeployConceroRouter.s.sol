// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroRouter} from "contracts/ConceroRouter/ConceroRouter.sol";
import {PauseDummy} from "contracts/PauseDummy/PauseDummy.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "contracts/Proxy/TransparentUpgradeableProxy.sol";

import {ConceroRouterBase} from "../../ConceroRouter/base/ConceroRouterBase.sol";
import {ConceroTest} from "../../utils/ConceroTest.sol";

import {DeployERC20, MockERC20} from "./DeployERC20.s.sol";

contract DeployConceroRouter is ConceroRouterBase {
    TransparentUpgradeableProxy internal conceroRouterProxy;
    ConceroRouter internal conceroRouter;

    function run() public returns (address) {
        DeployERC20 tokenDeployer = new DeployERC20();
        usdc = address(tokenDeployer.deployERC20("USD Coin", "USDC", 6));

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
        conceroRouter = new ConceroRouter(
            SRC_CHAIN_SELECTOR,
            usdc,
            [
                MOCK_DON_SIGNER_ADDRESS_0,
                MOCK_DON_SIGNER_ADDRESS_1,
                MOCK_DON_SIGNER_ADDRESS_2,
                MOCK_DON_SIGNER_ADDRESS_3
            ]
        );
        vm.stopPrank();

        setProxyImplementation(address(conceroRouter));
    }
}
