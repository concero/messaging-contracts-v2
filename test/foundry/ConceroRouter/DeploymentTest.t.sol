// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MessageConfigConstants} from "../../../contracts/Libraries/MessageLib.sol";
import {FeeToken, EvmDstChainData, EvmSrcChainData} from "../../../contracts/Common/MessageTypes.sol";
import {ConceroRouterStorage as s} from "../../../contracts/ConceroRouter/ConceroRouterStorage.sol";
import {ConceroRouter} from "../../../contracts/ConceroRouter/ConceroRouter.sol";
import {DeployConceroRouter} from "../scripts/DeployConceroRouter.s.sol";
import {Test} from "forge-std/src/Test.sol";
import {TransparentUpgradeableProxy} from "../../../contracts/Proxy/TransparentUpgradeableProxy.sol";

contract TestConceroRouter is Test {
    DeployConceroRouter internal deployScript;
    TransparentUpgradeableProxy internal conceroRouterProxy;
    ConceroRouter internal conceroRouter;
    using s for s.Router;
    using s for s.PriceFeed;

    address public proxyDeployer = vm.envAddress("PROXY_DEPLOYER_ADDRESS");
    address public deployer = vm.envAddress("DEPLOYER_ADDRESS");
    uint24 internal chainSelector = 1;

    function setUp() public {
        // Initialize the deployment script
        deployScript = new DeployConceroRouter();

        // Deploy ConceroRouter via the script
        address deployedProxy = deployScript.run();

        conceroRouterProxy = TransparentUpgradeableProxy(payable(deployedProxy));
        conceroRouter = ConceroRouter(payable(deployScript.getProxy()));
    }

    function test_ProxyDeployment() public {
        // Verify that the proxy address is not zero
        address proxyAddress = address(conceroRouterProxy);
        assertTrue(proxyAddress != address(0), "Proxy address should not be zero");

        // Retrieve the implementation address via assembly
        address implementation;
        assembly {
            implementation := sload(
                0x360894A13BA1A3210667C828492DB98DCA3E2076CC3735A920A3CA505D382BBC
            ) // EIP-1967 slot
        }
        assertTrue(implementation != address(0), "Implementation address should not be zero");
    }

    function testGetMessageFeeUSDC() public {
        // Mock data for the test
        uint256 clientMessageConfig = (uint256(FeeToken.usdc) <<
            MessageConfigConstants.OFFSET_FEE_TOKEN);
        bytes memory dstChainData = abi.encode(
            EvmDstChainData({receiver: address(0x123), gasLimit: 100000})
        );

        // Mock the expected gas price and rates in storage
        uint24 dstChainSelector = uint24(
            clientMessageConfig >> MessageConfigConstants.OFFSET_DST_CHAIN
        );

        // Start and stop the prank explicitly
        vm.startPrank(deployer);
        s.priceFeed().lastGasPrices[dstChainSelector] = 100 gwei;
        s.priceFeed().nativeNativeRates[dstChainSelector] = 1 ether; // 1:1 native-native rate
        s.priceFeed().nativeUsdcRate = 10 ** 6; // Mock USDC rate (1 USDC = 1 native token)
        vm.stopPrank();

        // Call the function to calculate the fee
        uint256 feeUSDC = conceroRouter.getMessageFeeUSDC(clientMessageConfig, dstChainData);

        // Expected fee calculation
        uint256 baseFee = 0.01 ether;
        uint256 gasPrice = 100 gwei;
        uint256 gasFeeNative = gasPrice * 100000; // gas price * gas limit
        uint256 adjustedGasFeeNative = (gasFeeNative * 1 ether) / 1 ether; // Adjusted gas fee
        uint256 totalFeeNative = baseFee + adjustedGasFeeNative;
        uint256 expectedFeeUSDC = (totalFeeNative * 10 ** 6) / 1 ether; // Convert to USDC

        // Assertions
        assertEq(feeUSDC, expectedFeeUSDC, "Incorrect USDC fee calculation");
    }

    function testSetProxyImplementation() public {
        // Deploy a new implementation for testing
        vm.startPrank(deployer);
        ConceroRouter newImplementation = new ConceroRouter(chainSelector);
        vm.stopPrank();

        // Update the proxy to point to the new implementation
        vm.startPrank(proxyDeployer);
        deployScript.setProxyImplementation(address(newImplementation));
        vm.stopPrank();
    }
}
