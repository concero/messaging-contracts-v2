// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ConceroRouterStorage as s} from "../../../contracts/ConceroRouter/ConceroRouterStorage.sol";
import {ConceroRouter} from "../../../contracts/ConceroRouter/ConceroRouter.sol";
import {DeployConceroRouter} from "../scripts/DeployConceroRouter.s.sol";
import {FeeToken, EvmDstChainData, EvmSrcChainData} from "../../../contracts/Common/MessageTypes.sol";
import {MessageConfigConstants} from "../../../contracts/Libraries/MessageLib.sol";
import {StorageSlot} from "../../../contracts/ConceroRouter/ConceroRouterStorage.sol";
import {Test} from "forge-std/src/Test.sol";
import {TransparentUpgradeableProxy} from "../../../contracts/Proxy/TransparentUpgradeableProxy.sol";
import {StorageLib} from "../../../contracts/Libraries/StorageLib.sol";

contract Storage is Test {
    DeployConceroRouter internal deployScript;
    TransparentUpgradeableProxy internal conceroRouterProxy;
    ConceroRouter internal conceroRouter;

    using s for s.Router;
    using s for s.PriceFeed;

    address public proxyDeployer = vm.envAddress("PROXY_DEPLOYER_ADDRESS");
    address public deployer = vm.envAddress("DEPLOYER_ADDRESS");

    bytes32 internal constant ROUTER_STORAGE_SLOT = keccak256("concero.router.storage");
    bytes32 internal constant PRICEFEED_STORAGE_SLOT = keccak256("concero.priceFeed.storage");

    function setUp() public {
        deployScript = new DeployConceroRouter();
        address deployedProxy = deployScript.run();

        conceroRouterProxy = TransparentUpgradeableProxy(payable(deployedProxy));
        conceroRouter = ConceroRouter(payable(deployScript.getProxy()));
    }

    function test_SetAndGetNonce() public {
        uint256 newNonce = 123;

        vm.startPrank(deployer);
        conceroRouter.setStorage(ROUTER_STORAGE_SLOT, bytes32(0), newNonce);

        assertEq(
            conceroRouter.getStorage(ROUTER_STORAGE_SLOT, bytes32(0)),
            newNonce,
            "Storage getter failed for nonce"
        );
        vm.stopPrank();
    }

    function test_SetAndGetLastGasPrice() public {
        uint24 chainSelector = 1234;
        uint256 gasPrice = 5000000000;

        bytes32 key = bytes32(uint256(chainSelector));

        vm.startPrank(deployer);
        conceroRouter.setStorage(PRICEFEED_STORAGE_SLOT, key, gasPrice);
        assertEq(
            conceroRouter.getStorage(PRICEFEED_STORAGE_SLOT, key),
            gasPrice,
            "Storage getter failed for lastGasPrice"
        );
        vm.stopPrank();
    }

    function test_SetStorageBulk() public {
        uint24[] memory chainSelectors = new uint24[](2);
        chainSelectors[0] = 1234;
        chainSelectors[1] = 5678;

        uint256[] memory gasPrices = new uint256[](2);
        gasPrices[0] = 5000000000;
        gasPrices[1] = 6000000000;

        bytes32[] memory slots = new bytes32[](2);
        bytes32[] memory keys = new bytes32[](2);
        bytes[] memory values = new bytes[](2);

        for (uint256 i = 0; i < 2; i++) {
            slots[i] = PRICEFEED_STORAGE_SLOT;
            keys[i] = bytes32(uint256(chainSelectors[i]));
            values[i] = abi.encode(gasPrices[i]);
        }

        vm.startPrank(deployer);
        conceroRouter.setStorageBulk(slots, keys, values);

        for (uint256 i = 0; i < 2; i++) {
            assertEq(
                conceroRouter.getStorage(PRICEFEED_STORAGE_SLOT, keys[i]),
                gasPrices[i],
                "Bulk storage update failed"
            );
        }
        vm.stopPrank();
    }

    function test_RevertInvalidStorageSlot() public {
        vm.expectRevert(StorageLib.InvalidStorageSlot.selector);

        bytes32 invalidSlot = keccak256("invalid.slot");

        vm.prank(deployer);
        conceroRouter.setStorage(invalidSlot, bytes32(0), 1);
    }

    function test_RevertLengthMismatch() public {
        bytes32[] memory slots = new bytes32[](2);
        bytes32[] memory keys = new bytes32[](1);
        bytes[] memory values = new bytes[](2);

        slots[0] = PRICEFEED_STORAGE_SLOT;
        slots[1] = ROUTER_STORAGE_SLOT;

        vm.expectRevert(StorageLib.LengthMismatch.selector);

        vm.prank(deployer);
        conceroRouter.setStorageBulk(slots, keys, values);
    }

    //    function testGetMessageFeeUSDC() public {
    //        uint256 clientMessageConfig = (uint256(FeeToken.usdc) <<
    //            MessageConfigConstants.OFFSET_FEE_TOKEN);
    //        bytes memory dstChainData = abi.encode(
    //            EvmDstChainData({receiver: address(0x123), gasLimit: 100000})
    //        );
    //
    //        uint24 dstChainSelector = uint24(
    //            clientMessageConfig >> MessageConfigConstants.OFFSET_DST_CHAIN
    //        );
    //
    //        vm.startPrank(deployer);
    //        s.priceFeed().lastGasPrices[dstChainSelector] = 100 gwei;
    //        s.priceFeed().nativeNativeRates[dstChainSelector] = 1 ether;
    //        s.priceFeed().nativeUsdcRate = 10 ** 6;
    //        vm.stopPrank();
    //
    //        uint256 feeUSDC = conceroRouter.getMessageFeeUSDC(clientMessageConfig, dstChainData);
    //
    //        uint256 baseFee = 0.01 ether;
    //        uint256 gasPrice = 100 gwei;
    //        uint256 gasFeeNative = gasPrice * 100000; // gas price * gas limit
    //        uint256 adjustedGasFeeNative = (gasFeeNative * 1 ether) / 1 ether;
    //        uint256 totalFeeNative = baseFee + adjustedGasFeeNative;
    //        uint256 expectedFeeUSDC = (totalFeeNative * 10 ** 6) / 1 ether;
    //
    //        assertEq(feeUSDC, expectedFeeUSDC, "Incorrect USDC fee calculation");
    //    }
}
