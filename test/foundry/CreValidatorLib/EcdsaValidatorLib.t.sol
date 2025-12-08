// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Test} from "forge-std/src/Test.sol";

import {CreValidatorLib} from "contracts/validators/CreValidatorLib/CreValidatorLib.sol";

contract EcdsaValidatorLibSignatureTest is Test {
    CreValidatorLib public validator;
    address public admin;
    uint256 public signerPrivateKey;
    address public signerAddress;

    function setUp() public {
        admin = makeAddr("admin");

        // Create a test signer
        signerPrivateKey = 0x1234567890123456789012345678901234567890123456789012345678901234;
        signerAddress = vm.addr(signerPrivateKey);

        // Deploy and initialize validator
        validator = new CreValidatorLib();
        validator.initialize(admin);

        // Setup validator with our test signer
        address[] memory signers = new address[](1);
        signers[0] = signerAddress;

        bool[] memory isAllowed = new bool[](1);
        isAllowed[0] = true;

        vm.prank(admin);
        validator.setAllowedSigners(signers, isAllowed);

        vm.prank(admin);
        validator.setMinSignersCount(1);

        // Setup a valid workflow ID
        bytes32 workflowId = keccak256("test-workflow");
        vm.prank(admin);
        validator.setIsWorkflowIdAllowed(workflowId, true);
    }

    /**
     * @notice This test demonstrates that standard Ethereum signatures pass validation
     */
    function test_standardEthereumSignature_Success() public view {
        // Create a mock message receipt
        bytes memory messageReceipt = abi.encodePacked("test message");
        bytes32 messageReceiptHash = keccak256(messageReceipt);

        // Build a mock CRE validation structure
        bytes memory rawReport = _buildMockRawReport(messageReceiptHash);
        bytes memory reportContext = new bytes(96); // Mock report context

        // Create validation hash (what will be signed)
        bytes32 validationHash = keccak256(abi.encodePacked(keccak256(rawReport), reportContext));

        // Sign with vm.sign() - produces STANDARD Ethereum signature with v=27 or v=28
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, validationHash);

        // Verify v is in standard format
        assertTrue(v == 27 || v == 28, "vm.sign should produce v=27 or v=28");

        // Encode signature in standard format
        bytes memory signature = abi.encodePacked(r, s, v);

        // Package signature for CreValidatorLib
        bytes[] memory signatures = new bytes[](1);
        signatures[0] = signature;

        // Build complete validation bytes
        bytes memory validation = abi.encodePacked(
            rawReport,
            reportContext,
            abi.encode(signatures)
        );

        assertTrue(validator.isValid(messageReceipt, validation));
    }

    /**
     * @notice This test demonstrates that EIP-155 signatures pass validation
     */
    function test_EIP155Signature_Success() public view {
        // Create a mock message receipt
        bytes memory messageReceipt = abi.encodePacked("test message");
        bytes32 messageReceiptHash = keccak256(messageReceipt);

        // Build a mock CRE validation structure
        bytes memory rawReport = _buildMockRawReport(messageReceiptHash);
        bytes memory reportContext = new bytes(96); // Mock report context

        // Create validation hash (what will be signed)
        bytes32 validationHash = keccak256(abi.encodePacked(keccak256(rawReport), reportContext));

        // Sign with vm.sign() - produces STANDARD Ethereum signature with v=27 or v=28
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, validationHash);

        // Verify initial v is in standard format
        assertTrue(v == 27 || v == 28, "vm.sign should produce v=27 or v=28");

        // Adjust v to EIP-155 format
        uint256 chainId = block.chainid; // Use current chain ID (e.g., 31337 in Foundry)
        uint8 recoveryId = v - 27; // 0 or 1
        v = uint8(chainId * 2 + 35 + recoveryId); // EIP-155 v (will be % 256 implicitly)

        // Verify v is in EIP-155 range (for most chain IDs, v >= 35)
        assertTrue(v >= 35, "Adjusted v should be in EIP-155 format (>=35)");

        // Encode signature in EIP-155 format
        bytes memory signature = abi.encodePacked(r, s, v);

        // Package signature for CreValidatorLib
        bytes[] memory signatures = new bytes[](1);
        signatures[0] = signature;

        // Build complete validation bytes
        bytes memory validation = abi.encodePacked(
            rawReport,
            reportContext,
            abi.encode(signatures)
        );

        assertTrue(validator.isValid(messageReceipt, validation));
    }

    /**
     * @notice This test demonstrates that CRE signatures pass validation
     */
    function test_CreSignatureFormat_Success() public view {
        // Create a mock message receipt
        bytes memory messageReceipt = abi.encodePacked("test message");
        bytes32 messageReceiptHash = keccak256(messageReceipt);

        // Build a mock CRE validation structure
        bytes memory rawReport = _buildMockRawReport(messageReceiptHash);
        bytes memory reportContext = new bytes(96); // Mock report context

        // Create validation hash (what will be signed)
        bytes32 validationHash = keccak256(abi.encodePacked(keccak256(rawReport), reportContext));

        // Sign with vm.sign() - produces STANDARD Ethereum signature with v=27 or v=28
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, validationHash);

        // Verify initial v is in standard format
        assertTrue(v == 27 || v == 28, "vm.sign should produce v=27 or v=28");

        uint8 recoveryId = v - 27; // 0 or 1
        v = recoveryId;

        // Verify v is in CRE format
        assertTrue(v == 0 || v == 1, "Adjusted v should be 0 or 1");
        bytes memory signature = abi.encodePacked(r, s, v);

        // Package signature for CreValidatorLib
        bytes[] memory signatures = new bytes[](1);
        signatures[0] = signature;

        // Build complete validation bytes
        bytes memory validation = abi.encodePacked(
            rawReport,
            reportContext,
            abi.encode(signatures)
        );

        assertTrue(validator.isValid(messageReceipt, validation));
    }

    /**
     * @notice Helper function to build a mock CRE raw report
     * @dev The report structure must match CreValidatorLib expectations
     */
    function _buildMockRawReport(bytes32 messageReceiptHash) internal view returns (bytes memory) {
        // Build a 141-byte mock raw report
        // Offsets based on CreValidatorLib constants:
        // version: offset 0, size 1
        // workflow_execution_id: offset 1, size 32
        // timestamp: offset 33, size 4
        // don_id: offset 37, size 4
        // don_config_version: offset 41, size 4
        // workflow_cid: offset 45, size 32 (THIS IS AT OFFSET 77 from memory start with length prefix)
        // workflow_name: offset 77, size 10
        // workflow_owner: offset 87, size 20
        // report_id: offset 107, size 2
        // messageReceiptHash: offset 109, size 32

        bytes memory report = new bytes(141);

        // Version (1 byte)
        report[0] = bytes1(uint8(1));

        // workflow_execution_id (32 bytes) - starts at offset 1
        bytes32 executionId = keccak256("execution");
        for (uint i = 0; i < 32; i++) {
            report[1 + i] = executionId[i];
        }

        // timestamp (4 bytes) - offset 33
        bytes4 timestamp = bytes4(uint32(block.timestamp));
        for (uint i = 0; i < 4; i++) {
            report[33 + i] = timestamp[i];
        }

        // don_id (4 bytes) - offset 37
        bytes4 donId = bytes4(uint32(1));
        for (uint i = 0; i < 4; i++) {
            report[37 + i] = donId[i];
        }

        // don_config_version (4 bytes) - offset 41
        bytes4 configVersion = bytes4(uint32(1));
        for (uint i = 0; i < 4; i++) {
            report[41 + i] = configVersion[i];
        }

        // workflow_cid (32 bytes) - offset 45
        // This will be at offset 77 when loaded into memory with length prefix
        bytes32 workflowId = keccak256("test-workflow");
        for (uint i = 0; i < 32; i++) {
            report[45 + i] = workflowId[i];
        }

        // workflow_name (10 bytes) - offset 77
        bytes10 workflowName = bytes10("testflow");
        for (uint i = 0; i < 10; i++) {
            report[77 + i] = workflowName[i];
        }

        // workflow_owner (20 bytes) - offset 87
        address owner = address(this);
        for (uint i = 0; i < 20; i++) {
            report[87 + i] = bytes20(owner)[i];
        }

        // report_id (2 bytes) - offset 107
        bytes2 reportId = bytes2(uint16(1));
        for (uint i = 0; i < 2; i++) {
            report[107 + i] = reportId[i];
        }

        // messageReceiptHash (32 bytes) - offset 109
        for (uint i = 0; i < 32; i++) {
            report[109 + i] = messageReceiptHash[i];
        }

        return report;
    }
}
