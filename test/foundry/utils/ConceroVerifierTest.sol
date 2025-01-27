import {ConceroTest} from "./ConceroTest.sol";
import {DeployConceroVerifier} from "../scripts/DeployConceroVerifier.s.sol";
import {TransparentUpgradeableProxy} from "../../../contracts/Proxy/TransparentUpgradeableProxy.sol";
import {ConceroVerifier} from "../../../contracts/ConceroVerifier/ConceroVerifier.sol";

abstract contract ConceroVerifierTest is ConceroTest {
    DeployConceroVerifier internal deployScript;
    TransparentUpgradeableProxy internal conceroVerifierProxy;
    ConceroVerifier internal conceroVerifier;

    function setUp() public virtual override {
        super.setUp();
        deployScript = new DeployConceroVerifier();
        address deployedProxy = deployScript.run();

        conceroVerifierProxy = TransparentUpgradeableProxy(payable(deployedProxy));
        conceroVerifier = ConceroVerifier(payable(deployScript.getProxy()));
    }
}
