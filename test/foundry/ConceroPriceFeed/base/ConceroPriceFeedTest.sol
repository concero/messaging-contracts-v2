// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {PriceFeedSlots} from "contracts/ConceroPriceFeed/libraries/StorageSlots.sol";
import {Namespaces} from "contracts/ConceroPriceFeed/libraries/Storage.sol";
import {ConceroPriceFeed} from "contracts/ConceroPriceFeed/ConceroPriceFeed.sol";

import {ConceroTest} from "../../utils/ConceroTest.sol";
import {DeployConceroPriceFeed} from "../../scripts/deploy/DeployConceroPriceFeed.s.sol";
import {ConceroPriceFeedBase} from "./ConceroPriceFeedBase.sol";

abstract contract ConceroPriceFeedTest is DeployConceroPriceFeed, ConceroTest {
    function setUp() public virtual override(ConceroPriceFeedBase, ConceroTest) {
        super.setUp();

        conceroPriceFeed = ConceroPriceFeed(payable(deploy()));
    }
}
