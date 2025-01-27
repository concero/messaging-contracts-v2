// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import {Script} from "forge-std/src/Script.sol";
import {VmSafe} from "forge-std/src/Vm.sol";

library EnvGetters {
    VmSafe internal constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    function getClfRouterAddress() public view returns (address) {
        uint256 chainId = block.chainid;

        if (chainId == vm.envUint("BASE_CHAIN_ID")) {
            return vm.envAddress("CLF_ROUTER_BASE");
        } else if (chainId == vm.envUint("ARBITRUM_CHAIN_ID")) {
            return vm.envAddress("CLF_ROUTER_ARBITRUM");
        } else if (chainId == vm.envUint("POLYGON_CHAIN_ID")) {
            return vm.envAddress("CLF_ROUTER_POLYGON");
        } else if (chainId == vm.envUint("AVALANCHE_CHAIN_ID")) {
            return vm.envAddress("CLF_ROUTER_AVALANCHE");
        } else if (chainId == vm.envUint("OPTIMISM_CHAIN_ID")) {
            return vm.envAddress("CLF_ROUTER_OPTIMISM");
        } else if (chainId == vm.envUint("ETHEREUM_CHAIN_ID")) {
            return vm.envAddress("CLF_ROUTER_ETHEREUM");
        }

        return vm.envAddress("CLF_ROUTER_BASE");
    }

    function getCLfSubId() public view returns (uint64) {
        uint256 chainId = block.chainid;
        uint256 res = vm.envUint("CLF_SUBID_BASE");

        if (chainId == vm.envUint("BASE_CHAIN_ID")) {
            res = vm.envUint("CLF_SUBID_BASE");
        } else if (chainId == vm.envUint("ARBITRUM_CHAIN_ID")) {
            res = vm.envUint("CLF_SUBID_ARBITRUM");
        } else if (chainId == vm.envUint("POLYGON_CHAIN_ID")) {
            res = vm.envUint("CLF_SUBID_POLYGON");
        } else if (chainId == vm.envUint("AVALANCHE_CHAIN_ID")) {
            res = vm.envUint("CLF_SUBID_AVALANCHE");
        } else if (chainId == vm.envUint("OPTIMISM_CHAIN_ID")) {
            res = vm.envUint("CLF_SUBID_OPTIMISM");
        } else if (chainId == vm.envUint("ETHEREUM_CHAIN_ID")) {
            res = vm.envUint("CLF_SUBID_ETHEREUM");
        }

        return uint64(res);
    }

    function getClfDonId() public view returns (bytes32) {
        uint256 chainId = block.chainid;

        if (chainId == vm.envUint("BASE_CHAIN_ID")) {
            return vm.envBytes32("CLF_DONID_BASE");
        } else if (chainId == vm.envUint("ARBITRUM_CHAIN_ID")) {
            return vm.envBytes32("CLF_DONID_ARBITRUM");
        } else if (chainId == vm.envUint("POLYGON_CHAIN_ID")) {
            return vm.envBytes32("CLF_DONID_POLYGON");
        } else if (chainId == vm.envUint("AVALANCHE_CHAIN_ID")) {
            return vm.envBytes32("CLF_DONID_AVALANCHE");
        } else if (chainId == vm.envUint("OPTIMISM_CHAIN_ID")) {
            return vm.envBytes32("CLF_DONID_OPTIMISM");
        } else if (chainId == vm.envUint("ETHEREUM_CHAIN_ID")) {
            return vm.envBytes32("CLF_DONID_ETHEREUM");
        }

        return vm.envBytes32("CLF_DONID_BASE");
    }

    function getLinkAddress() public view returns (address) {
        uint256 chainId = block.chainid;

        if (chainId == vm.envUint("BASE_CHAIN_ID")) {
            return vm.envAddress("LINK_BASE");
        } else if (chainId == vm.envUint("ARBITRUM_CHAIN_ID")) {
            return vm.envAddress("LINK_ARBITRUM");
        } else if (chainId == vm.envUint("POLYGON_CHAIN_ID")) {
            return vm.envAddress("LINK_POLYGON");
        } else if (chainId == vm.envUint("AVALANCHE_CHAIN_ID")) {
            return vm.envAddress("LINK_AVALANCHE");
        } else if (chainId == vm.envUint("OPTIMISM_CHAIN_ID")) {
            return vm.envAddress("LINK_OPTIMISM");
        } else if (chainId == vm.envUint("ETHEREUM_CHAIN_ID")) {
            return vm.envAddress("LINK_ETHEREUM");
        }

        return vm.envAddress("LINK_BASE");
    }
}
