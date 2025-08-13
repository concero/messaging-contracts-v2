// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ConceroRouterHarness} from "contracts/ConceroRouter/ConceroRouterHarness.sol";
import {PauseDummy} from "contracts/PauseDummy/PauseDummy.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "contracts/Proxy/TransparentUpgradeableProxy.sol";

import {ConceroRouterBase} from "../../ConceroRouter/base/ConceroRouterBase.sol";
import {ConceroTest} from "../../utils/ConceroTest.sol";

contract DeployConceroRouter is ConceroRouterBase {
    TransparentUpgradeableProxy internal conceroRouterProxy;
    ConceroRouterHarness internal conceroRouter;

    function setUp() public virtual override {
        super.setUp();
    }

    function setProxyImplementation(address implementation) public {
        vm.startPrank(proxyDeployer);
        ITransparentUpgradeableProxy(address(conceroRouterProxy)).upgradeToAndCall(
            implementation,
            bytes("")
        );
        vm.stopPrank();
    }

    function deploy() public returns (address) {
        return deploy(SRC_CHAIN_SELECTOR, address(conceroPriceFeed));
    }

    function deploy(uint24 chainSelector, address priceFeed) public returns (address) {
        address implementation = _deployImplementation(
            chainSelector,
            priceFeed,
            CONCERO_VERIFIER_ADDRESS,
            i_conceroVerifierSubscriptionId,
            [
                MOCK_DON_SIGNER_ADDRESS_0,
                MOCK_DON_SIGNER_ADDRESS_1,
                MOCK_DON_SIGNER_ADDRESS_2,
                MOCK_DON_SIGNER_ADDRESS_3
            ]
        );
        _deployProxy(implementation);

        return address(conceroRouterProxy);
    }

    function deploy(
        uint24 chainSelector,
        address conceroPriceFeed,
        address verifier,
        uint64 verifierSubId,
        address[4] memory clfSigners
    ) public returns (address) {
        address implementation = _deployImplementation(
            chainSelector,
            conceroPriceFeed,
            verifier,
            verifierSubId,
            clfSigners
        );
        _deployProxy(implementation);
        return address(conceroRouterProxy);
    }

    function _deployProxy(address implementation) internal {
        vm.startPrank(proxyDeployer);
        conceroRouterProxy = new TransparentUpgradeableProxy(implementation, proxyDeployer, "");
        vm.stopPrank();
    }

    function _deployImplementation(
        uint24 chainSelector,
        address conceroPriceFeed,
        address verifier,
        uint64 verifierSubId,
        address[4] memory clfSigners
    ) internal returns (address) {
        vm.startPrank(deployer);

        conceroRouter = new ConceroRouterHarness(
            chainSelector,
            conceroPriceFeed,
            verifier,
            verifierSubId,
            clfSigners
        );
        vm.stopPrank();

        return address(conceroRouter);
    }
}
