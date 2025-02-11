// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ConceroBaseScript} from "../../scripts/ConceroBaseScript.s.sol";

contract ConceroVerifierBase is ConceroBaseScript {
    //deployment vars
    address public clfRouter;
    bytes32 public clfDonId;
    uint64 public clfSubscriptionId;
    uint64 public clfSecretsVersion;
    uint8 public clfSecretsSlotId;
    bytes32 public clfMessageReportRequestJsHashSum;
    bytes32 public clfOperatorRegistrationJsHashSum;
    uint16 public clfPremiumFeeBpsUsd;
    uint32 public clfCallbackGasLimit;

    constructor() {
        clfDonId = vm.envBytes32("CLF_DONID_ARBITRUM");
        clfSubscriptionId = uint64(vm.envUint("CLF_SUBID_ARBITRUM"));
        clfSecretsVersion = uint64(vm.envUint("CLF_DON_SECRETS_VERSION_ARBITRUM"));
        clfSecretsSlotId = uint8(0);
        clfMessageReportRequestJsHashSum = vm.parseBytes32(
            "0x66756e2d657468657265756d2d6d61696e6e65742d3100000000000000000000"
        );
        clfOperatorRegistrationJsHashSum = vm.parseBytes32(
            "0x66756e2d657468657265756d2d6d61696e6e65742d3100000000000000000000"
        );
        clfPremiumFeeBpsUsd = uint16(300); // 0.03 USD
        clfCallbackGasLimit = uint32(100_000);
    }
}
