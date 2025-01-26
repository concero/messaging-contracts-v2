// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test} from "forge-std/src/Test.sol";
import {Vm} from "forge-std/src/Vm.sol";
import {console} from "forge-std/src/Console.sol";

import {ConceroVerifier} from "../../../contracts/ConceroVerifier/ConceroVerifier.sol";
import {VerifierSlots} from "../../../contracts/ConceroVerifier/libraries/StorageSlots.sol";
import {DeployConceroVerifier} from "../scripts/DeployConceroVerifier.s.sol";
import {Constants} from "../../../contracts/common/Constants.sol";
import {Utils as CommonUtils} from "../../../contracts/common/libraries/Utils.sol";

import {Namespaces} from "../../../contracts/ConceroVerifier/libraries/Storage.sol";
import {Types} from "../../../contracts/ConceroVerifier/libraries/Types.sol";
import {Errors} from "../../../contracts/ConceroVerifier/libraries/Errors.sol";
import {TransparentUpgradeableProxy} from "../../../contracts/Proxy/TransparentUpgradeableProxy.sol";

contract ConceroVerifierTest is Test {
    DeployConceroVerifier internal deployScript;
    TransparentUpgradeableProxy internal conceroVerifierProxy;
    ConceroVerifier internal conceroVerifier;

    address public operator = address(0x1);
    address public deployer = vm.envAddress("DEPLOYER_ADDRESS");
    address public nonOperator = address(0x2);
    address public user = address(0x123);
    uint24 public chainSelector = 1;
    uint256 public constant NATIVE_USD_RATE = 2000e18; // Assuming 1 ETH = $2000

    function setUp() public {
        deployScript = new DeployConceroVerifier();
        address deployedProxy = deployScript.run();

        conceroVerifierProxy = TransparentUpgradeableProxy(payable(deployedProxy));
        conceroVerifier = ConceroVerifier(payable(deployScript.getProxy()));

        vm.deal(operator, 100 ether);

        vm.prank(deployer);
        conceroVerifier.setNativeUsdRate(NATIVE_USD_RATE);
    }

    function test_OperatorDeposit() public {
        uint256 minimumDepositNative = _calculateMinimumDepositNative();

        vm.prank(operator);
        conceroVerifier.operatorDeposit{value: minimumDepositNative}();

        assertEq(
            conceroVerifier.getOperatorDeposit(operator),
            minimumDepositNative,
            "Operator deposit amount mismatch"
        );
    }

    function test_OperatorDepositBelowMinimum() public {
        uint256 minimumDepositNative = _calculateMinimumDepositNative() - 1;
        uint256 belowMinimum = minimumDepositNative - 1;

        vm.prank(operator);
        vm.expectRevert(Errors.InsufficientOperatorDeposit.selector);
        conceroVerifier.operatorDeposit{value: belowMinimum}();
    }

    function test_OperatorRegistration() public {
        test_OperatorDeposit();
        Types.ChainType[] memory chainTypes = new Types.ChainType[](1);
        chainTypes[0] = Types.ChainType.EVM;

        Types.OperatorRegistrationAction[] memory actions = new Types.OperatorRegistrationAction[](
            1
        );
        actions[0] = Types.OperatorRegistrationAction.Register;

        bytes[] memory addresses = new bytes[](1);
        addresses[0] = abi.encode(operator);

        vm.prank(operator);
        vm.recordLogs();
        conceroVerifier.requestOperatorRegistration(chainTypes, actions, addresses);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestId;
        for (uint i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("RequestSent(bytes32)")) {
                requestId = bytes32(entries[i].topics[1]);
                break;
            }
        }

        uint256 storedStatus = conceroVerifier.getStorage(
            Namespaces.VERIFIER,
            VerifierSlots.pendingCLFRequests,
            requestId
        );

        assertEq(
            storedStatus,
            uint256(Types.CLFRequestStatus.Pending),
            "CLF request should be pending"
        );
    }

    function test_RestrictedOperatorFunctions() public {
        Types.MessageReportRequest memory request;

        vm.prank(nonOperator);
        vm.expectRevert(Errors.UnauthorizedOperator.selector);
        conceroVerifier.requestMessageReport(request);
    }

    function _calculateMinimumDepositNative() internal view returns (uint256) {
        uint256 minimumDepositNative = CommonUtils.convertUSDBPSToNative(
            Constants.OPERATOR_DEPOSIT_MINIMUM_BPS_USD,
            NATIVE_USD_RATE
        );

        return minimumDepositNative;
    }

    receive() external payable {}
}
