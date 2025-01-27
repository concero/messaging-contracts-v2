// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import {Script} from "forge-std/src/Script.sol";

import {DeployERC20, MockERC20} from "./DeployERC20.s.sol";
import {ConceroVerifier} from "contracts/ConceroVerifier/ConceroVerifier.sol";
import {EnvGetters} from "../utils/EnvGetters.sol";
import {PauseDummy} from "../../../contracts/PauseDummy/PauseDummy.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "contracts/Proxy/TransparentUpgradeableProxy.sol";
import {DeployMockCLFRouter, MockCLFRouter} from "./DeployCLFRouter.s.sol";

contract DeployConceroVerifier is Script {
    TransparentUpgradeableProxy internal conceroVerifierProxy;
    ConceroVerifier internal conceroVerifier;

    address public proxyDeployer = vm.envAddress("PROXY_DEPLOYER_ADDRESS");
    address public deployer = vm.envAddress("DEPLOYER_ADDRESS");
    uint24 public chainSelector = uint24(1);
    address public USDC; // = vm.envAddress("USDC_ARBITRUM");
    address public clfRouter; // = vm.envAddress("CLF_ROUTER_ARBITRUM");

    bytes32 public clfDonId = vm.envBytes32("CLF_DONID_ARBITRUM");
    uint64 public clfSubscriptionId = uint64(vm.envUint("CLF_SUBID_ARBITRUM"));
    uint64 public clfSecretsVersion = uint64(vm.envUint("CLF_DON_SECRETS_VERSION_ARBITRUM"));
    uint8 public clfSecretsSlotId = uint8(0);
    bytes32 public clfMessageReportRequestJsHashSum =
        vm.parseBytes32("0x66756e2d657468657265756d2d6d61696e6e65742d3100000000000000000000");
    bytes32 public clfOperatorRegistrationJsHashSum =
        vm.parseBytes32("0x66756e2d657468657265756d2d6d61696e6e65742d3100000000000000000000");

    function run() public returns (address) {
        DeployERC20 tokenDeployer = new DeployERC20();
        USDC = address(tokenDeployer.deployERC20("USD Coin", "USDC", 6));

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
            chainSelector,
            USDC,
            clfRouter,
            clfDonId,
            clfSubscriptionId,
            clfSecretsVersion,
            clfSecretsSlotId,
            clfMessageReportRequestJsHashSum,
            clfOperatorRegistrationJsHashSum
        );
        vm.stopPrank();

        setProxyImplementation(address(conceroVerifier));
    }
}
