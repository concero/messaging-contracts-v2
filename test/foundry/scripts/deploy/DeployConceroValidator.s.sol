// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import "../../../../contracts/ConceroValidator/libraries/Types.sol";
import {CLFParams} from "contracts/ConceroValidator/libraries/Types.sol";
import {ConceroValidator} from "contracts/ConceroValidator/ConceroValidator.sol";
import {DeployConceroPriceFeed} from "./DeployConceroPriceFeed.s.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "contracts/Proxy/TransparentUpgradeableProxy.sol";
import {Script} from "forge-std/src/Script.sol";

contract DeployConceroValidator is Script {
    address public s_deployer = vm.envAddress("DEPLOYER_ADDRESS");
    address public s_proxyDeployer = vm.envAddress("PROXY_DEPLOYER_ADDRESS");
    TransparentUpgradeableProxy internal s_conceroValidatorProxy;
    ConceroValidator internal s_conceroValidator;

    function deploy(
        bytes32 clfMessageReportRequestJsHashSum,
        uint24 chainSelector,
        address clfRouter,
        bytes32 clfDonId,
        uint64 clfSubscriptionId,
        address priceFeed
    ) public returns (address) {
        address implementation = _deployImplementation(
            clfMessageReportRequestJsHashSum,
            chainSelector,
            clfRouter,
            clfDonId,
            clfSubscriptionId,
            priceFeed
        );
        _deployProxy(implementation);
        return address(s_conceroValidatorProxy);
    }

    function setProxyImplementation(address implementation) public {
        vm.startPrank(s_proxyDeployer);
        ITransparentUpgradeableProxy(address(s_conceroValidatorProxy)).upgradeToAndCall(
            implementation,
            bytes("")
        );
        vm.stopPrank();
    }

    function _deployProxy(address implementation) internal {
        vm.startPrank(s_proxyDeployer);
        s_conceroValidatorProxy = new TransparentUpgradeableProxy(
            implementation,
            s_proxyDeployer,
            ""
        );
        vm.stopPrank();
    }

    function _deployImplementation(
        bytes32 clfMessageReportRequestJsHashSum,
        uint24 chainSelector,
        address clfRouter,
        bytes32 clfDonId,
        uint64 clfSubscriptionId,
        address priceFeed
    ) internal returns (address) {
        vm.startPrank(s_deployer);
        CLFParams memory clfParams = CLFParams({
            router: clfRouter,
            donId: clfDonId,
            subscriptionId: clfSubscriptionId,
            requestCLFMessageReportJsCodeHash: clfMessageReportRequestJsHashSum
        });

        s_conceroValidator = new ConceroValidator(chainSelector, priceFeed, clfParams);
        vm.stopPrank();

        return address(s_conceroValidator);
    }
}
