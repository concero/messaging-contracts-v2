// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ValidatorLib} from "contracts/ValidatorLib/ValidatorLib.sol";
import {ValidatorLibBase} from "../../ValidatorLib/base/ValidatorLibBase.sol";

contract DeployValidatorLib is ValidatorLibBase {
    ValidatorLib internal validatorLib;

    function setUp() public virtual override {
        super.setUp();
    }

    function deploy() public returns (address) {
        return deploy(DST_CHAIN_SELECTOR, address(conceroPriceFeed));
    }

    function deploy(uint24 chainSelector, address priceFeed) public returns (address) {
        vm.startPrank(deployer);

        validatorLib = new ValidatorLib(
            chainSelector,
            priceFeed,
            CONCERO_VERIFIER_ADDRESS,
            i_conceroVerifierSubscriptionId,
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
