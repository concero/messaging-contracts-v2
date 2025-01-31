// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ConceroTest} from "./ConceroTest.sol";
import {DeployConceroVerifier} from "../scripts/DeployConceroVerifier.s.sol";
import {TransparentUpgradeableProxy} from "../../../contracts/Proxy/TransparentUpgradeableProxy.sol";
import {ConceroVerifier} from "../../../contracts/ConceroVerifier/ConceroVerifier.sol";

abstract contract ConceroVerifierTest is ConceroTest {
    DeployConceroVerifier internal deployScript;
    TransparentUpgradeableProxy internal conceroVerifierProxy;
    ConceroVerifier internal conceroVerifier;

    function setUp() public virtual {
        deployScript = new DeployConceroVerifier();
        address deployedProxy = deployScript.run();

        conceroVerifierProxy = TransparentUpgradeableProxy(payable(deployedProxy));
        conceroVerifier = ConceroVerifier(payable(deployScript.getProxy()));
    }
}
