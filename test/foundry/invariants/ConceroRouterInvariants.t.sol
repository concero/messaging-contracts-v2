// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonErrors} from "contracts/common/CommonErrors.sol";
import {ConceroRouter} from "contracts/ConceroRouter/ConceroRouter.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {ConceroRouterTest} from "../ConceroRouter/base/ConceroRouterTest.sol";
import {console} from "forge-std/src/console.sol";

contract RouterHandler {
    ConceroRouter internal immutable i_conceroRouter;
    address internal immutable i_validatorLib;
    address internal immutable i_relayerLib;

    mapping(bytes32 => bool isProcessed) internal isMessageProcessed;
    bool internal s_isIdUniq = true;

    constructor(address conceroRouter, address validatorLib, address relayerLib) {
        i_conceroRouter = ConceroRouter(payable(conceroRouter));
        i_validatorLib = validatorLib;
        i_relayerLib = relayerLib;
    }

    function conceroSend() external {
        address[] memory validators = new address[](1);
        validators[0] = i_validatorLib;

        IConceroRouter.MessageRequest memory messageRequest = IConceroRouter.MessageRequest({
            dstChainSelector: 1,
            srcBlockConfirmations: 2,
            feeToken: address(0),
            dstChainData: "dst chain data",
            validatorLibs: validators,
            relayerLib: i_relayerLib,
            validatorConfigs: new bytes[](1),
            relayerConfig: "config",
            payload: "payload"
        });

        uint256 fee = i_conceroRouter.getMessageFee(messageRequest);
        bytes32 messageId = i_conceroRouter.conceroSend{value: fee}(messageRequest);

        if (isMessageProcessed[messageId]) {
            s_isIdUniq = false;
        }

        isMessageProcessed[messageId] = true;
    }

    function isIdUniq() external view returns (bool) {
        return s_isIdUniq;
    }
}

contract ConceroRouterInvariants is ConceroRouterTest {
    RouterHandler internal s_routerHandler;

    function setUp() public override {
        super.setUp();

        s_routerHandler = new RouterHandler(address(s_conceroRouter), s_validatorLib, s_relayerLib);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = RouterHandler.conceroSend.selector;

        deal(address(s_routerHandler), 10000 ether);

        targetContract(address(s_routerHandler));
        targetSelector(FuzzSelector({addr: address(s_routerHandler), selectors: selectors}));
    }

    function invariant_uniqId() public view {
        assert(s_routerHandler.isIdUniq());
    }
}
