pragma solidity 0.8.28;

import {Script} from "forge-std/src/Script.sol";

abstract contract ConceroBaseScript is Script {
    address public immutable deployer;
    address public immutable proxyDeployer;

    address public constant operator = address(0x1);
    address public constant nonOperator = address(0x2);
    address public constant user = address(0x123);

    uint24 public constant chainSelector = 8453;

    address public constant MOCK_DON_SIGNER_ADDRESS_0 = 0x0004C7EdCF9283D3bc3C1309939b3E887bb9d98b;
    address public constant MOCK_DON_SIGNER_ADDRESS_1 = 0x000437D9bE1C11B748e8B4C349b818eE82682E9f;
    address public constant MOCK_DON_SIGNER_ADDRESS_2 = 0x000E512Da9116546247eE54Ffef6319E00331E1B;
    address public constant MOCK_DON_SIGNER_ADDRESS_3 = 0x0001E5818621C01908e989851ECB899Af3d57bDc;

    uint256 public constant MOCK_DON_SIGNER_PRIVATE_KEY_0 =
        0xc4811b8c87ec913b43de310600815ed870bc9984121627252d077c38ab76183d;
    uint256 public constant MOCK_DON_SIGNER_PRIVATE_KEY_1 =
        0xe55e1246012033fa1c89a1891a61bc4da0f1da259ec648a0fb6d3384f278f267;
    uint256 public constant MOCK_DON_SIGNER_PRIVATE_KEY_2 =
        0x36c5485ba3a564b7753ea1f3ba81d8b574b8b31e97abd9053c8eee938a8abce8;
    uint256 public constant MOCK_DON_SIGNER_PRIVATE_KEY_3 =
        0x31ec7a7d750fd8fdb2f80d6ba2a426afab415a2000092bcf529e6002697b2e31;

    constructor() {
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        proxyDeployer = vm.envAddress("PROXY_DEPLOYER_ADDRESS");
    }
}
