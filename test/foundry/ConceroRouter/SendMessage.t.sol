pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test} from "forge-std/src/Test.sol";
import {Vm} from "forge-std/src/Vm.sol";

import {Message, MessageLibConstants} from "../../../contracts/common/libraries/Message.sol";
import {Types} from "../../../contracts/ConceroRouter/libraries/Types.sol";

import {Storage as s} from "../../../contracts/ConceroRouter/libraries/Storage.sol";
import {RouterSlots as rs} from "../../../contracts/ConceroRouter/libraries/StorageSlots.sol";
import {ConceroTypes} from "../../../contracts/ConceroClient/ConceroTypes.sol";
import {ConceroUtils} from "../../../contracts/ConceroClient/ConceroUtils.sol";
import {ConceroRouter} from "../../../contracts/ConceroRouter/ConceroRouter.sol";
import {TransparentUpgradeableProxy} from "../../../contracts/Proxy/TransparentUpgradeableProxy.sol";
import {Errors} from "../../../contracts/ConceroRouter/libraries/Errors.sol";
import {DeployConceroRouter} from "../scripts/DeployConceroRouter.s.sol";

contract SendMessage is Test {
    DeployConceroRouter internal deployScript;
    TransparentUpgradeableProxy internal conceroRouterProxy;
    ConceroRouter internal conceroRouter;

    address public proxyDeployer = vm.envAddress("PROXY_DEPLOYER_ADDRESS");
    address public deployer = vm.envAddress("DEPLOYER_ADDRESS");
    address public user = address(0x123);
    bytes32 internal constant ROUTER_STORAGE_SLOT = keccak256("concero.router.storage");
    uint24 internal constant DST_CHAIN_SELECTOR = 8453;

    uint256 internal constant CLIENT_MESSAGE_CONFIG =
        (uint256(DST_CHAIN_SELECTOR) << MessageLibConstants.OFFSET_DST_CHAIN) | // dstChainSelector
            (1 << MessageLibConstants.OFFSET_MIN_SRC_CONF) | // minSrcConfirmations
            (1 << MessageLibConstants.OFFSET_MIN_DST_CONF) | // minDstConfirmations
            (0 << MessageLibConstants.OFFSET_RELAYER_CONF) | // relayerConfig
            (0 << MessageLibConstants.OFFSET_CALLBACKABLE) | // isCallbackable
            (uint256(Types.FeeToken.native) << MessageLibConstants.OFFSET_FEE_TOKEN); // feeToken

    bytes internal dstChainData;
    bytes internal message;

    function setUp() public {
        deployScript = new DeployConceroRouter();
        address deployedProxy = deployScript.run();

        conceroRouterProxy = TransparentUpgradeableProxy(payable(deployedProxy));
        conceroRouter = ConceroRouter(payable(deployScript.getProxy()));

        dstChainData = abi.encode(
            Types.EvmDstChainData({receiver: address(0x456), gasLimit: 100000})
        );
        message = "Test message";

        vm.deal(user, 100 ether);
    }

    function test_conceroSend() public {
        vm.startPrank(user);
        vm.recordLogs();

        ConceroTypes.ClientMessageConfig memory config = ConceroTypes.ClientMessageConfig({
            dstChainSelector: DST_CHAIN_SELECTOR,
            minSrcConfirmations: 1,
            minDstConfirmations: 1,
            relayerConfig: 0,
            isCallbackable: false,
            feeToken: uint8(Types.FeeToken.native)
        });

        uint256 clientMessageConfig = ConceroUtils._packClientMessageConfig(config);

        uint256 initialNonce = conceroRouter.getStorage(ROUTER_STORAGE_SLOT, rs.NONCE);
        uint256 messageFee = conceroRouter.getMessageFeeNative(clientMessageConfig, dstChainData);

        bytes32 messageId = conceroRouter.conceroSend{value: messageFee}(
            clientMessageConfig,
            dstChainData,
            message
        );

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bool eventFound = false;
        for (uint i = 0; i < entries.length; i++) {
            if (
                entries[i].topics[0] == keccak256("ConceroMessageSent(bytes32,uint256,bytes,bytes)")
            ) {
                eventFound = true;
                (
                    uint256 internalMessageConfig,
                    bytes memory dstChainDataFromEvent,
                    bytes memory messageFromEvent
                ) = abi.decode(entries[i].data, (uint256, bytes, bytes));

                Message.validateInternalMessage(internalMessageConfig, dstChainDataFromEvent);

                assertEq(entries[i].topics[1], messageId, "Message ID mismatch");
                assertEq(dstChainDataFromEvent, dstChainData, "Destination chain data mismatch");
                assertEq(messageFromEvent, message, "Message mismatch");
            }
        }
        assertTrue(eventFound, "ConceroMessageSent event not found");

        uint256 finalNonce = conceroRouter.getStorage(ROUTER_STORAGE_SLOT, rs.NONCE);
        assertEq(finalNonce, initialNonce + 1, "Nonce should be incremented by 1");

        vm.stopPrank();
    }

    function test_RevertInsufficientFee() public {
        vm.startPrank(user);

        uint256 messageFee = conceroRouter.getMessageFeeNative(CLIENT_MESSAGE_CONFIG, dstChainData);
        uint256 insufficientFee = messageFee - 1;

        vm.expectRevert(Errors.InsufficientFee.selector);
        conceroRouter.conceroSend{value: insufficientFee}(
            CLIENT_MESSAGE_CONFIG,
            dstChainData,
            message
        );

        vm.stopPrank();
    }

    function test_RevertInvalidMessageConfig() public {
        vm.startPrank(user);

        uint256 invalidConfig = 0;
        uint256 messageFee = conceroRouter.getMessageFeeNative(CLIENT_MESSAGE_CONFIG, dstChainData);

        vm.expectRevert();
        conceroRouter.conceroSend{value: messageFee}(invalidConfig, dstChainData, message);

        vm.stopPrank();
    }
}
