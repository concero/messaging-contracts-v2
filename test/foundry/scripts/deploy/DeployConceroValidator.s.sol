// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "contracts/Proxy/TransparentUpgradeableProxy.sol";
import {ConceroValidator} from "contracts/ConceroValidator/ConceroValidator.sol";
import {ConceroValidatorBase} from "../../ConceroValidator/base/ConceroValidatorBase.sol";
import {CLFParams} from "contracts/ConceroValidator/libraries/Types.sol";

contract DeployConceroValidator is ConceroValidatorBase {
    TransparentUpgradeableProxy internal conceroValidatorProxy;
    ConceroValidator internal conceroValidator;

    function setUp() public virtual override {
        super.setUp();
    }

    function setProxyImplementation(address implementation) public {
        vm.startPrank(proxyDeployer);
        ITransparentUpgradeableProxy(address(conceroValidatorProxy)).upgradeToAndCall(
            implementation,
            bytes("")
        );
        vm.stopPrank();
    }

    function deploy() public returns (address) {
        address implementation = _deployImplementation();
        _deployProxy(implementation);
        return address(conceroValidatorProxy);
    }

    function _deployProxy(address implementation) internal {
        vm.startPrank(proxyDeployer);
        conceroValidatorProxy = new TransparentUpgradeableProxy(implementation, proxyDeployer, "");
        vm.stopPrank();
    }

    function _deployImplementation() internal returns (address) {
        vm.startPrank(deployer);

        CLFParams memory clfParams = CLFParams({
            router: clfRouter,
            donId: clfDonId,
            subscriptionId: clfSubscriptionId,
            requestCLFMessageReportJsCodeHash: clfMessageReportRequestJsHashSum
        });

        conceroValidator = new ConceroValidator(
            SRC_CHAIN_SELECTOR,
            address(conceroPriceFeed),
            clfParams
        );
        vm.stopPrank();

        return address(conceroValidator);
    }
}
