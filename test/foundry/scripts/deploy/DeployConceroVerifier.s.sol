// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {console} from "forge-std/src/Console.sol";

import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "contracts/Proxy/TransparentUpgradeableProxy.sol";
import {PauseDummy} from "contracts/PauseDummy/PauseDummy.sol";
import {ConceroVerifier} from "contracts/ConceroVerifier/ConceroVerifier.sol";

import {ConceroVerifierBase} from "../../ConceroVerifier/base/ConceroVerifierBase.sol";

import {DeployMockCLFRouter, MockCLFRouter} from "./DeployMockCLFRouter.s.sol";
import {CLFParams} from "contracts/ConceroVerifier/libraries/Types.sol";

contract DeployConceroVerifier is ConceroVerifierBase {
    TransparentUpgradeableProxy internal conceroVerifierProxy;
    ConceroVerifier internal conceroVerifier;

    function setUp() public virtual override {
        super.setUp();
    }

    function setProxyImplementation(address implementation) public {
        vm.startPrank(proxyDeployer);
        ITransparentUpgradeableProxy(address(conceroVerifierProxy)).upgradeToAndCall(
            implementation,
            bytes("")
        );
        vm.stopPrank();
    }

    function deploy() public returns (address) {
        address implementation = _deployImplementation();
        _deployProxy(implementation);
        return address(conceroVerifierProxy);
    }

    function _deployProxy(address implementation) internal {
        vm.startPrank(proxyDeployer);
        conceroVerifierProxy = new TransparentUpgradeableProxy(implementation, proxyDeployer, "");
        vm.stopPrank();
    }

    function _deployImplementation() internal returns (address) {
        vm.startPrank(deployer);

        CLFParams memory clfParams = CLFParams({
            router: clfRouter,
            donId: clfDonId,
            subscriptionId: clfSubscriptionId,
            donHostedSecretsVersion: clfSecretsVersion,
            donHostedSecretsSlotId: clfSecretsSlotId,
            premiumFeeUsdBps: clfPremiumFeeBpsUsd,
            callbackGasLimit: clfCallbackGasLimit,
            requestCLFMessageReportJsCodeHash: clfMessageReportRequestJsHashSum,
            requestOperatorRegistrationJsCodeHash: clfOperatorRegistrationJsHashSum
        });

        conceroVerifier = new ConceroVerifier(SRC_CHAIN_SELECTOR, usdc, clfParams);
        vm.stopPrank();

        return address(conceroVerifier);
    }
}
