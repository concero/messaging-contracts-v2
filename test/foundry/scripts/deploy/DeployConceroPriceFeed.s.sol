// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroPriceFeed} from "contracts/ConceroPriceFeed/ConceroPriceFeed.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "contracts/Proxy/TransparentUpgradeableProxy.sol";

import {ConceroPriceFeedBase} from "../../ConceroPriceFeed/base/ConceroPriceFeedBase.sol";

contract DeployConceroPriceFeed is ConceroPriceFeedBase {
    TransparentUpgradeableProxy internal conceroPriceFeedProxy;

    function setProxyImplementation(address implementation) public {
        vm.startPrank(proxyDeployer);
        ITransparentUpgradeableProxy(address(conceroPriceFeedProxy)).upgradeToAndCall(
            implementation,
            bytes("")
        );
        vm.stopPrank();
    }

    function deploy() public returns (address) {
        address implementation = _deployImplementation(SRC_CHAIN_SELECTOR, feedUpdater);
        _deployProxy(implementation);
        return address(conceroPriceFeedProxy);
    }

    function _deployProxy(address implementation) internal {
        vm.startPrank(proxyDeployer);
        conceroPriceFeedProxy = new TransparentUpgradeableProxy(implementation, proxyDeployer, "");
        vm.stopPrank();
    }

    function _deployImplementation(
        uint24 srcChainSelector,
        address _feedUpdater
    ) internal returns (address) {
        vm.startPrank(deployer);
        conceroPriceFeed = new ConceroPriceFeed(srcChainSelector, _feedUpdater);
        vm.stopPrank();

        return address(conceroPriceFeed);
    }
}
