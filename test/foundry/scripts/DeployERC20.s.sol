// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "forge-std/src/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {EnvGetters} from "../utils/EnvGetters.sol";

contract MockERC20 is ERC20 {
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimalsValue) ERC20(name, symbol) {
        _decimals = decimalsValue;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

contract DeployERC20 is Script {
    address public initialHolder = vm.envAddress("PROXY_DEPLOYER_ADDRESS");
    uint256 public initialSupply = 1_000_000;

    function deployERC20(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public returns (MockERC20) {
        MockERC20 token = new MockERC20(name, symbol, decimals);

        if (initialSupply > 0) {
            token.mint(initialHolder, initialSupply);
        }

        return token;
    }
}
