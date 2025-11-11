// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Base} from "../common/Base.sol";
import {CLF} from "./modules/CLF.sol";
import {Owner} from "./modules/Owner.sol";
import {Validator} from "./modules/Validator.sol";
import {CLFParams} from "./libraries/Types.sol";

contract ConceroValidator is CLF, Validator, Owner {
    constructor(
        uint24 chainSelector,
        address conceroPriceFeed,
        CLFParams memory clfParams
    )
        Base(chainSelector, conceroPriceFeed)
        CLF(
            clfParams.router,
            clfParams.donId,
            clfParams.subscriptionId,
            clfParams.requestCLFMessageReportJsCodeHash
        )
    {}

    receive() external payable {}

    fallback() external payable {}
}
