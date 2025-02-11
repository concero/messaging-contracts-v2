// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ConceroVerifierBase} from "../../ConceroVerifier/base/ConceroVerifierBase.sol";
import {ConceroVerifier} from "contracts/ConceroVerifier/ConceroVerifier.sol";
import {DeployERC20, MockERC20} from "./DeployERC20.s.sol";
import {DeployMockCLFRouter, MockCLFRouter} from "./DeployMockCLFRouter.s.sol";
import {PauseDummy} from "contracts/PauseDummy/PauseDummy.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "contracts/Proxy/TransparentUpgradeableProxy.sol";
import {console} from "forge-std/src/Console.sol";

contract DeployConceroVerifier is ConceroVerifierBase {
    TransparentUpgradeableProxy internal conceroVerifierProxy;
    ConceroVerifier internal conceroVerifier;

    function run() public returns (address) {
        DeployERC20 tokenDeployer = new DeployERC20();
        usdc = address(tokenDeployer.deployERC20("USD Coin", "USDC", 6));

        DeployMockCLFRouter routerDeployer = new DeployMockCLFRouter();
        clfRouter = routerDeployer.run();

        _deployConceroVerifier();
        return address(conceroVerifier);
    }

    function run(uint256 forkId) public returns (address) {
        vm.selectFork(forkId);
        return run();
    }

    function setProxyImplementation(address implementation) public {
        vm.startPrank(proxyDeployer);
        ITransparentUpgradeableProxy(address(conceroVerifierProxy)).upgradeToAndCall(
            implementation,
            bytes("")
        );
        vm.stopPrank();
    }

    function getProxy() public view returns (address) {
        return address(conceroVerifierProxy);
    }

    function _deployConceroVerifier() internal {
        _deployConceroVerifierProxy();
        _deployAndSetImplementation();
    }

    function _deployConceroVerifierProxy() internal {
        vm.startPrank(proxyDeployer);
        conceroVerifierProxy = new TransparentUpgradeableProxy(
            address(new PauseDummy()),
            proxyDeployer,
            ""
        );
        vm.stopPrank();
    }

    function _deployAndSetImplementation() internal {
        vm.startPrank(deployer);
        conceroVerifier = new ConceroVerifier(
            SRC_CHAIN_SELECTOR,
            usdc,
            clfRouter,
            clfDonId,
            clfSubscriptionId,
            clfSecretsVersion,
            clfSecretsSlotId,
            clfPremiumFeeBpsUsd,
            clfCallbackGasLimit,
            clfMessageReportRequestJsHashSum,
            clfOperatorRegistrationJsHashSum
        );
        vm.stopPrank();

        setProxyImplementation(address(conceroVerifier));
    }
}
