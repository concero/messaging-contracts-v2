// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ValidatorLib} from "contracts/ValidatorLib/ValidatorLib.sol";
import {DeployConceroPriceFeed} from "./DeployConceroPriceFeed.s.sol";
import {Script} from "forge-std/src/Script.sol";

contract DeployValidatorLib is Script {
    address public constant MOCK_DON_SIGNER_ADDRESS_0 = 0x0004C7EdCF9283D3bc3C1309939b3E887bb9d98b;
    address public constant MOCK_DON_SIGNER_ADDRESS_1 = 0x000437D9bE1C11B748e8B4C349b818eE82682E9f;
    address public constant MOCK_DON_SIGNER_ADDRESS_2 = 0x000E512Da9116546247eE54Ffef6319E00331E1B;
    address public constant MOCK_DON_SIGNER_ADDRESS_3 = 0x0001E5818621C01908e989851ECB899Af3d57bDc;
    address internal constant CONCERO_VERIFIER_ADDRESS = address(0x11);

    address public s_deployer = vm.envAddress("DEPLOYER_ADDRESS");
    uint64 public s_conceroValidatorSubscriptionId = 12;

    ValidatorLib internal validatorLib;

    function deploy(uint24 chainSelector, address priceFeed) public returns (address) {
        vm.startPrank(s_deployer);

        validatorLib = new ValidatorLib(
            chainSelector,
            priceFeed,
            CONCERO_VERIFIER_ADDRESS,
            s_conceroValidatorSubscriptionId,
            [
                MOCK_DON_SIGNER_ADDRESS_0,
                MOCK_DON_SIGNER_ADDRESS_1,
                MOCK_DON_SIGNER_ADDRESS_2,
                MOCK_DON_SIGNER_ADDRESS_3
            ]
        );

        vm.stopPrank();

        return address(validatorLib);
    }
}
