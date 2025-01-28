pragma solidity 0.8.28;

import {ConceroTest} from "./ConceroTest.sol";
import {DeployConceroRouter} from "../scripts/DeployConceroRouter.s.sol";
import {TransparentUpgradeableProxy} from "../../../contracts/Proxy/TransparentUpgradeableProxy.sol";
import {ConceroRouter} from "../../../contracts/ConceroRouter/ConceroRouter.sol";

abstract contract ConceroRouterTest is ConceroTest {
    DeployConceroRouter internal deployScript;
    TransparentUpgradeableProxy internal conceroRouterProxy;
    ConceroRouter internal conceroRouter;

    function setUp() public virtual {
        deployScript = new DeployConceroRouter();
        address deployedProxy = deployScript.run();

        conceroRouterProxy = TransparentUpgradeableProxy(payable(deployedProxy));
        conceroRouter = ConceroRouter(payable(deployScript.getProxy()));
    }
}
