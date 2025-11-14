// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Script} from "forge-std/src/Script.sol";

import {CLFParams} from "contracts/ConceroValidator/libraries/Types.sol";
import {ConceroValidator} from "contracts/ConceroValidator/ConceroValidator.sol";
import {DeployConceroPriceFeed} from "./DeployConceroPriceFeed.s.sol";

contract DeployConceroValidator is Script {
    ConceroValidator internal s_conceroValidator;

    address public s_deployer = vm.envAddress("DEPLOYER_ADDRESS");
    address public s_proxyDeployer = vm.envAddress("PROXY_DEPLOYER_ADDRESS");
    bytes32 public s_clfDonId = vm.envBytes32("CLF_DONID_ARBITRUM");

    bytes32 public s_clfMessageReportRequestJsHashSum =
        vm.parseBytes32("0x66756e2d657468657265756d2d6d61696e6e65742d3100000000000000000000");
    uint64 public s_conceroValidatorSubscriptionId = uint64(vm.envUint("CLF_SUBID_LOCALHOST"));

    function deploy(uint24 chainSelector, address priceFeed, address clfRouter) public returns (address) {
        CLFParams memory clfParams = CLFParams({
            router: clfRouter,
            donId: s_clfDonId,
            subscriptionId: s_conceroValidatorSubscriptionId,
            requestCLFMessageReportJsCodeHash: s_clfMessageReportRequestJsHashSum
        });

        vm.prank(s_deployer);
        s_conceroValidator = new ConceroValidator(chainSelector, priceFeed, clfParams);

        return address(s_conceroValidator);
    }
}
